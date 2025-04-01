
//-----------------------------------------------------------------------------
//
// (c) Copyright 2020-2024 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and
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
// Project    : Accelerator System Design
// File       : dsc_byp_c2h_mm.sv
// Version    : 5.0
//Description : This module performs the following actions. 
// 1. Provides credits to dsc_crdt interface
// 2. Stores the descriptors received on c2h_dsc_byp_out interface in a FIFO
// 3. Counts the Bytes written by CDMA to DDR through FIFO and compares it with BTT input
// 4. Initiates C2H transfer when byte count in #3 matches with BTT input
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

module dsc_byp_c2h
  (
   
   input  logic						user_clk,
   input  logic						user_reset_n,
   
   input  logic [31:0]				BTT,
   //input  logic [11:0]				c2h_byp_qid,
   //qdma_c2h_dsc_byp_ctrl - [15:0] = dma0_dsc_crdt_in_0_crdt, [16]= dsc_crdt_in_vld, [17] = c2h_channel (CPM_PCIE_NOC_0 or CPM_PCIE_NOC_1), [18] = dsc_crdt_in_fence, [31:20] = c2h_byp_qid
   input  logic [31:0]				qdma_c2h_dsc_byp_ctrl,
   input  logic [31:0]				cdma_trfr_sz,
   input  logic						cdma_introut,
   
   input  logic [1:0] 				c2h_dsc_bypass,
   input  logic 					c2h_mm_marker_req,
   input  logic 					c2h_mm_channel_sel,
   output logic 					c2h_mm_marker_rsp,
   output logic             		c2h_st_marker_rsp,
   
   input  logic [255:0]             c2h_byp_out_dsc,
   input  logic [2:0]               c2h_byp_out_fmt,
   input  logic                     c2h_byp_out_st_mm,
   input  logic [1:0]               c2h_byp_out_dsc_sz,
   input  logic [11:0]              c2h_byp_out_qid,
   input  logic                     c2h_byp_out_error,
   input  logic [11:0]              c2h_byp_out_func,
   input  logic [15:0]              c2h_byp_out_cidx,
   input  logic [2:0]               c2h_byp_out_port_id,
   input  logic [6:0]               c2h_byp_out_pfch_tag,
   input  logic                     c2h_byp_out_vld,
   output logic                     c2h_byp_out_rdy,
   
   output   logic [63:0]            c2h_byp_in_mm_0_radr,
   output   logic [63:0]            c2h_byp_in_mm_0_wadr,
   output   logic [15:0]            c2h_byp_in_mm_0_len,
   output   logic                   c2h_byp_in_mm_0_mrkr_req,
   output   logic                   c2h_byp_in_mm_0_sdi,
   output   logic [11:0]            c2h_byp_in_mm_0_qid,
   output   logic                   c2h_byp_in_mm_0_error,
   output   logic [11:0]            c2h_byp_in_mm_0_func,
   output   logic [15:0]            c2h_byp_in_mm_0_cidx,
   output   logic [2:0]             c2h_byp_in_mm_0_port_id,
   output   logic                   c2h_byp_in_mm_0_no_dma,
   output   logic                   c2h_byp_in_mm_0_vld,
   input    logic                   c2h_byp_in_mm_0_rdy,
   
   output   logic [63:0]            c2h_byp_in_mm_1_radr,
   output   logic [63:0]            c2h_byp_in_mm_1_wadr,
   output   logic [15:0]            c2h_byp_in_mm_1_len,
   output   logic                   c2h_byp_in_mm_1_mrkr_req,
   output   logic                   c2h_byp_in_mm_1_sdi,
   output   logic [11:0]            c2h_byp_in_mm_1_qid,
   output   logic                   c2h_byp_in_mm_1_error,
   output   logic [11:0]            c2h_byp_in_mm_1_func,
   output   logic [15:0]            c2h_byp_in_mm_1_cidx,
   output   logic [2:0]             c2h_byp_in_mm_1_port_id,
   output   logic                   c2h_byp_in_mm_1_no_dma,
   output   logic                   c2h_byp_in_mm_1_vld,
   input    logic                   c2h_byp_in_mm_1_rdy,

   output   logic [63:0]            c2h_byp_in_st_csh_addr,
   output   logic [11:0]            c2h_byp_in_st_csh_qid,
   output   logic                   c2h_byp_in_st_csh_error,
   output   logic [11:0]            c2h_byp_in_st_csh_func,
   output   logic [2:0]             c2h_byp_in_st_csh_port_id,
   output   logic [6:0]             c2h_byp_in_st_csh_pfch_tag,
   output   logic                   c2h_byp_in_st_csh_vld,
   input    logic                   c2h_byp_in_st_csh_rdy,
   input    logic [6:0]   			pfch_byp_tag,
   
   output	logic					c2h_mm_data_rdy_intr,
   input	logic					c2h_mm_data_rdy_intr_clr

   );

   wire 								    c2h_csh_byp;
   wire 								    c2h_sim_byp;
   
   (* MARK_DEBUG="true" *)  logic	[31:0] wr_byte_fifo_2_ddr_cnt;   

  logic			cdma_introut_ff;
  (* MARK_DEBUG="true" *)  logic			cdma_introut_posedge;
  
  always @(posedge user_clk) 
   begin
		if(!user_reset_n) 
			cdma_introut_ff <= 1'b0;
		else
			cdma_introut_ff <= cdma_introut;
	end
	
 assign cdma_introut_posedge = cdma_introut & ~cdma_introut_ff;
   
   always @(posedge user_clk) 
   begin
        //fifo_2_ddr_cnt needs to be cleared after C2H transfer initiation is finished.This is required to generate user interrupt for the next H2C transfer to C2H transfer iteration. 
		if (!user_reset_n | (c2h_mm_data_rdy_intr_clr && c2h_mm_data_rdy_intr)) begin  
			wr_byte_fifo_2_ddr_cnt <= 32'h0;
		end
		else begin
			if(cdma_introut_posedge) 
				wr_byte_fifo_2_ddr_cnt <= wr_byte_fifo_2_ddr_cnt + cdma_trfr_sz;
			else
				wr_byte_fifo_2_ddr_cnt <= wr_byte_fifo_2_ddr_cnt;	
		end
	end
	
	always @(posedge user_clk) 
	begin
		if (!user_reset_n | c2h_mm_data_rdy_intr_clr) begin
			c2h_mm_data_rdy_intr <= 1'b0;
		end
		else begin
			if((|BTT != 0) && (wr_byte_fifo_2_ddr_cnt == BTT) && ~c2h_mm_data_rdy_intr)
				c2h_mm_data_rdy_intr <= 1'b1;
			else
				c2h_mm_data_rdy_intr <= c2h_mm_data_rdy_intr;	
		end
	end	

   // c2h_csh_byp is used for C2H St Cash Bypass and also C2H MM bypass looback.
   assign c2h_csh_byp = (c2h_dsc_bypass == 2'b01) ? 1'b1 : 1'b0; // 2'b01 : Cache dsc bypass/MM
   assign c2h_sim_byp = (c2h_dsc_bypass == 2'b10) ? 1'b1 : 1'b0; // 2'b10 : Simple dsc_bypass
   
   //c2h_byp_out_fmt == 3'b1 : is marker responce, all other values are reserved

//   assign c2h_st_marker_rsp = c2h_byp_out_rdy & c2h_byp_out_fmt & c2h_byp_out_vld;
   assign c2h_st_marker_rsp = (c2h_byp_out_fmt == 3'b1 ) & c2h_byp_out_vld & ~c2h_byp_out_st_mm;
   assign c2h_mm_marker_rsp = (c2h_byp_out_fmt == 3'b1 ) & c2h_byp_out_vld & c2h_byp_out_st_mm;

   assign c2h_byp_out_rdy        = (c2h_byp_out_fmt == 3'b1) ? 1'b1 :
				   c2h_csh_byp & c2h_byp_out_st_mm ? c2h_byp_in_mm_0_rdy :
				   c2h_csh_byp & ~c2h_byp_out_st_mm ? c2h_byp_in_st_csh_rdy :
				   c2h_sim_byp & c2h_byp_in_st_csh_rdy;

// MM
   assign c2h_byp_in_mm_0_mrkr_req = c2h_mm_channel_sel ? 1'b0	:  c2h_mm_marker_req;
   assign c2h_byp_in_mm_0_radr     = 64'h0;
   assign c2h_byp_in_mm_0_wadr     = c2h_mm_channel_sel ? 64'h0	:  c2h_byp_out_dsc[191:128];
   assign c2h_byp_in_mm_0_len      = c2h_mm_channel_sel ? 16'h0	:  c2h_byp_out_dsc[79:64];
   assign c2h_byp_in_mm_0_sdi      = c2h_mm_channel_sel ? 1'b0	:  c2h_byp_out_dsc[94];  // eop. send sdi at last desciptor.
   assign c2h_byp_in_mm_0_qid      = c2h_mm_channel_sel ? 12'h0	:  c2h_byp_out_qid;
   assign c2h_byp_in_mm_0_error    = c2h_mm_channel_sel ? 1'b0	:  c2h_byp_out_error;
   assign c2h_byp_in_mm_0_func     = c2h_mm_channel_sel ? 12'h0	:  c2h_byp_out_func;
   assign c2h_byp_in_mm_0_cidx     = c2h_mm_channel_sel ? 16'h0	:  c2h_byp_out_cidx;
   assign c2h_byp_in_mm_0_port_id  = c2h_mm_channel_sel ? 3'h0	:  c2h_byp_out_port_id;
   assign c2h_byp_in_mm_0_no_dma   = 1'b0;
   assign c2h_byp_in_mm_0_vld      = c2h_mm_channel_sel ? 1'b0	:  c2h_mm_marker_req | (c2h_csh_byp & ~c2h_byp_out_fmt[0] ? c2h_byp_out_st_mm & c2h_byp_out_vld : 1'b0);
   
   assign c2h_byp_in_mm_1_mrkr_req = c2h_mm_channel_sel ?	c2h_mm_marker_req 			: 1'b0;
   assign c2h_byp_in_mm_1_radr     = 64'h0;
   assign c2h_byp_in_mm_1_wadr     = c2h_mm_channel_sel ?	c2h_byp_out_dsc[191:128]	: 64'h0;
   assign c2h_byp_in_mm_1_len      = c2h_mm_channel_sel ?	c2h_byp_out_dsc[79:64]		: 16'h0;
   assign c2h_byp_in_mm_1_sdi      = c2h_mm_channel_sel ?	c2h_byp_out_dsc[94]			: 1'b0;  // eop. send sdi at last desciptor.
   assign c2h_byp_in_mm_1_qid      = c2h_mm_channel_sel ?	c2h_byp_out_qid				: 12'h0;
   assign c2h_byp_in_mm_1_error    = c2h_mm_channel_sel ?	c2h_byp_out_error			: 1'b0;
   assign c2h_byp_in_mm_1_func     = c2h_mm_channel_sel ?	c2h_byp_out_func			: 12'h0;
   assign c2h_byp_in_mm_1_cidx     = c2h_mm_channel_sel ?	c2h_byp_out_cidx			: 16'h0;
   assign c2h_byp_in_mm_1_port_id  = c2h_mm_channel_sel ?	c2h_byp_out_port_id			: 3'h0;
   assign c2h_byp_in_mm_1_no_dma   = 1'b0;
   assign c2h_byp_in_mm_1_vld      = c2h_mm_channel_sel ?	c2h_mm_marker_req | (c2h_csh_byp & ~c2h_byp_out_fmt[0] ? c2h_byp_out_st_mm & c2h_byp_out_vld : 1'b0) : 1'b0;

//ST Cache/Simple mode
   assign c2h_byp_in_st_csh_addr     = c2h_byp_out_dsc[63:0];
   assign c2h_byp_in_st_csh_qid      = c2h_byp_out_qid;
   assign c2h_byp_in_st_csh_error    = c2h_byp_out_error;
   assign c2h_byp_in_st_csh_func     = c2h_byp_out_func;
   assign c2h_byp_in_st_csh_port_id  = c2h_byp_out_port_id;
   assign c2h_byp_in_st_csh_pfch_tag = c2h_sim_byp ? pfch_byp_tag : c2h_byp_out_pfch_tag;  // for simple bypass use prefetch tag register
   assign c2h_byp_in_st_csh_vld      = c2h_csh_byp | c2h_sim_byp  & ~c2h_byp_out_fmt[0] ? ~c2h_byp_out_st_mm & c2h_byp_out_vld : 1'b0;

endmodule // dsc_bypass

