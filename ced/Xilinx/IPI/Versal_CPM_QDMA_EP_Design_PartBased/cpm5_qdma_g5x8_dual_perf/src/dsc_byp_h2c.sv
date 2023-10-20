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
// File       : dsc_byp_h2c.sv
// Version    : 5.0
//-----------------------------------------------------------------------------

module dsc_byp_h2c
  (
   input 	       clk,
   input 	       resetn,
   input 	       h2c_dsc_bypass,
   input [15:0]        sdi_count_reg,
   input 	       h2c_mm_marker_req,
   input 	       h2c_st_marker_req,
   // Descriptor Bypass Out for mdma
   input logic [255:0] h2c_byp_out_dsc,
   input logic [2:0]   h2c_byp_out_fmt,
   input logic 	       h2c_byp_out_st_mm,
   input logic [1:0]   h2c_byp_out_dsc_sz,
   input logic [11:0]  h2c_byp_out_qid,
   input logic 	       h2c_byp_out_error,
   input logic [11:0]  h2c_byp_out_func,
   input logic         h2c_byp_out_mm_chn,
   input logic [15:0]  h2c_byp_out_cidx,
   input logic [2:0]   h2c_byp_out_port_id,
   input logic 	       h2c_byp_out_vld,
   output logic        h2c_byp_out_rdy,
   
   // Desciptor Bypass for mdma 
   output logic [63:0] h2c_byp_in_mm_radr,
   output logic [63:0] h2c_byp_in_mm_wadr,
   output logic [15:0] h2c_byp_in_mm_len,
   output logic        h2c_byp_in_mm_mrkr_req,
   output logic        h2c_byp_in_mm_sdi,
   output logic [11:0] h2c_byp_in_mm_qid,
   output logic        h2c_byp_in_mm_error,
   output logic [11:0] h2c_byp_in_mm_func,
   output logic [15:0] h2c_byp_in_mm_cidx,
   output logic [2:0]  h2c_byp_in_mm_port_id,
   output logic        h2c_byp_in_mm_no_dma,
   output logic        h2c_byp_in_mm_vld,
   input logic 	       h2c_byp_in_mm_rdy,

   // Desciptor Bypass for mdma 
   output logic [63:0] h2c_byp_in_st_addr,
   output logic [15:0] h2c_byp_in_st_len,
   output logic        h2c_byp_in_st_eop,
   output logic        h2c_byp_in_st_sop,
   output logic        h2c_byp_in_st_mrkr_req,
   output logic        h2c_byp_in_st_sdi,
   output logic [11:0] h2c_byp_in_st_qid,
   output logic        h2c_byp_in_st_error,
   output logic [11:0] h2c_byp_in_st_func,
   output logic [15:0] h2c_byp_in_st_cidx,
   output logic [2:0]  h2c_byp_in_st_port_id,
   output logic        h2c_byp_in_st_no_dma,
   output logic        h2c_byp_in_st_vld,
   input logic 	       h2c_byp_in_st_rdy

   );

   logic 	       mm_fifo_full;
   logic 	       st_fifo_full;
   
   assign h2c_byp_out_rdy     = ~mm_fifo_full | ~st_fifo_full;
   
   // AXI-MM H2C bypass
   localparam MM_FIFO_WIDTH = 1+3+12+12+16+256;
   logic 	       mm_fifo_rden;
   logic 	       mm_fifo_empty;
   logic 	       mm_fifo_wren;
   logic [255:0]       mm_dout_dsc;
   logic [7:0] 	       mm_count_sdi;
   logic 	       mm_send_sdi;
   
   assign mm_send_sdi = (mm_count_sdi[7:0] == sdi_count_reg[7:0]-1);
   
   always @(posedge clk) begin
      if (~resetn)
	mm_count_sdi <= 0;
      else begin
	 mm_count_sdi[7:0] <= (mm_count_sdi[7:0] == sdi_count_reg[7:0]) ? 'h0 :
			      (h2c_byp_in_mm_vld & h2c_byp_in_mm_rdy & mm_dout_dsc[94]) ? mm_count_sdi[7:0] + 1 :
			      mm_count_sdi[7:0];
      end
   end
   
   assign mm_fifo_wren        = h2c_byp_out_vld & h2c_byp_out_st_mm & ~mm_fifo_full;
   assign mm_fifo_rden        = h2c_byp_in_mm_rdy & ~mm_fifo_empty;
   assign h2c_byp_in_mm_vld   = (h2c_dsc_bypass & ~mm_fifo_empty );
   
   assign h2c_byp_in_mm_mrkr_req = h2c_mm_marker_req;
   assign h2c_byp_in_mm_radr     = mm_dout_dsc[63:0];
   assign h2c_byp_in_mm_wadr     = mm_dout_dsc[191:128];
   assign h2c_byp_in_mm_len      = mm_dout_dsc[79:64];
   assign h2c_byp_in_mm_sdi      = mm_send_sdi & mm_dout_dsc[94];  // eop. send sdi at last discriptor;
   assign h2c_byp_in_mm_no_dma   = 1'b0;
   
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
      ) xpm_fifo_desc_h2c_MM_i 
       (
	.sleep           (1'b0),
	.rst             (~resetn),
	.wr_clk          (clk),
	.wr_en           (mm_fifo_wren),
	.din             ({h2c_byp_out_error, h2c_byp_out_port_id, h2c_byp_out_qid, h2c_byp_out_func, h2c_byp_out_cidx, h2c_byp_out_dsc}),
	.full            (mm_fifo_full),
	.prog_full       (mm_prog_full),
	.wr_data_count   (),
	.overflow        (overflow),
	.wr_rst_busy     (),
	.rd_en           (mm_fifo_rden),
	.dout            ({h2c_byp_in_mm_error, h2c_byp_in_mm_port_id, h2c_byp_in_mm_qid, h2c_byp_in_mm_func, h2c_byp_in_mm_cidx, mm_dout_dsc}),
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
   
// AXI-ST H2C

   localparam ST_FIFO_WIDTH = 1+3+12+12+16+128;
   logic 	       st_fifo_rden;
   logic 	       st_fifo_empty;
   logic 	       st_fifo_wren;
   logic [127:0]       st_dout_dsc;

   logic  	 st_send_sdi;

 /*  
   logic [255:0][7:0]  st_count_sdi;
   logic [7:0] 	       sdi_lookup;
   
   assign sdi_lookup = h2c_byp_in_st_qid[7:0];
   
   assign st_send_sdi = (st_count_sdi[sdi_lookup] == sdi_count_reg[7:0]-1);

   always @(posedge clk) begin
      if (~resetn)
	st_count_sdi <= 0;
      else begin
	 st_count_sdi[sdi_lookup] <= (st_count_sdi[sdi_lookup] == sdi_count_reg[7:0]) ? 'h0 : 
		                     (h2c_byp_in_st_vld & h2c_byp_in_st_rdy & h2c_byp_in_st_eop) ? st_count_sdi[sdi_lookup] + 1 : 
						 st_count_sdi[sdi_lookup];
      end
   end
*/
  
   logic [7:0]   st_count_sdi;
   assign st_send_sdi = (st_count_sdi == sdi_count_reg[7:0]-1);
   
   always @(posedge clk) begin
      if (~resetn)
	st_count_sdi <= 0;
      else begin
	 st_count_sdi <= (st_count_sdi == sdi_count_reg[7:0]) ? 'h0 : 
			 (h2c_byp_in_st_vld & h2c_byp_in_st_rdy & h2c_byp_in_st_eop) ? st_count_sdi + 1 : 
			 st_count_sdi;
      end
   end
  
   assign st_fifo_wren        = h2c_byp_out_vld & ~h2c_byp_out_st_mm & ~st_fifo_full;
   assign st_fifo_rden        = h2c_byp_in_st_rdy & ~st_fifo_empty;
   assign h2c_byp_in_st_vld   = ( h2c_dsc_bypass & ~st_fifo_empty );
   
   assign h2c_byp_in_st_mrkr_req = h2c_st_marker_req;
   assign h2c_byp_in_st_addr     = st_dout_dsc[127:64];
   assign h2c_byp_in_st_len      = st_dout_dsc[47:32];
   assign h2c_byp_in_st_eop      = st_dout_dsc[49];
   assign h2c_byp_in_st_sop      = st_dout_dsc[48];
   assign h2c_byp_in_st_sdi      = st_send_sdi & st_dout_dsc[49]; // eop. send sdi at last discriptor;
   assign h2c_byp_in_st_no_dma   = 1'b0;

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
      ) xpm_fifo_desc_h2c_ST_i 
       (
	.sleep           (1'b0),
	.rst             (~resetn),
	.wr_clk          (clk),
	.wr_en           (st_fifo_wren),
	.din             ({h2c_byp_out_error, h2c_byp_out_port_id, h2c_byp_out_qid, h2c_byp_out_func, h2c_byp_out_cidx, h2c_byp_out_dsc[127:0]}),
	.full            (st_fifo_full),
	.prog_full       (st_prog_full),
	.wr_data_count   (),
	.overflow        (),
	.wr_rst_busy     (),
	.rd_en           (st_fifo_rden),
	.dout            ({h2c_byp_in_st_error, h2c_byp_in_st_port_id, h2c_byp_in_st_qid, h2c_byp_in_st_func, h2c_byp_in_st_cidx, st_dout_dsc}),
	.empty           (st_fifo_empty),
	.prog_empty      (),
	.rd_data_count   (),
	.underflow       (underflow),
	.rd_rst_busy     (rd_rst_busy),
	.injectsbiterr   (1'b0),
	.injectdbiterr   (1'b0),
	.sbiterr         (),
	.dbiterr         ()
	);

endmodule // dsc_bypass

