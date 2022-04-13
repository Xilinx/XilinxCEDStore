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
   
   input [1:0] c2h_dsc_bypass,
   input c2h_mm_marker_req,
   output c2h_mm_marker_rsp,
   output logic                                                           c2h_st_marker_rsp,
   input  logic [255:0]                                                   c2h_byp_out_dsc,
   input  logic [2:0]                                                     c2h_byp_out_fmt,
   input  logic                                                           c2h_byp_out_st_mm,
   input  logic [1:0]                                                     c2h_byp_out_dsc_sz,
   input  logic [10:0]                                                    c2h_byp_out_qid,
   input  logic                                                           c2h_byp_out_error,
   input  logic [11:0]                                                    c2h_byp_out_func,
   input  logic [15:0]                                                    c2h_byp_out_cidx,
   input  logic [2:0]                                                     c2h_byp_out_port_id,
   input  logic [6:0]                                                     c2h_byp_out_pfch_tag,
   input  logic                                                           c2h_byp_out_vld,
   output logic                                                           c2h_byp_out_rdy,
   
   output   logic [63:0]                                                    c2h_byp_in_mm_radr,
   output   logic [63:0]                                                    c2h_byp_in_mm_wadr,
   output   logic [15:0]                                                    c2h_byp_in_mm_len,
   output   logic                                                           c2h_byp_in_mm_mrkr_req,
   output   logic                                                           c2h_byp_in_mm_sdi,
   output   logic [10:0]                                                    c2h_byp_in_mm_qid,
   output   logic                                                           c2h_byp_in_mm_error,
   output   logic [11:0]                                                    c2h_byp_in_mm_func,
   output   logic [15:0]                                                    c2h_byp_in_mm_cidx,
   output   logic [2:0]                                                     c2h_byp_in_mm_port_id,
   output   logic                                                           c2h_byp_in_mm_no_dma,
   output   logic                                                           c2h_byp_in_mm_vld,
   input    logic                                                           c2h_byp_in_mm_rdy,

   output   logic [63:0]                                                    c2h_byp_in_st_csh_addr,
   output   logic [10:0]                                                    c2h_byp_in_st_csh_qid,
   output   logic                                                           c2h_byp_in_st_csh_error,
   output   logic [11:0]                                                    c2h_byp_in_st_csh_func,
   output   logic [2:0]                                                     c2h_byp_in_st_csh_port_id,
   output   logic [6:0]                                                     c2h_byp_in_st_csh_pfch_tag,
   output   logic                                                           c2h_byp_in_st_csh_vld,
   input    logic                                                           c2h_byp_in_st_csh_rdy,
   input logic [6:0]   pfch_byp_tag

   );

   wire 								    c2h_csh_byp;
   wire 								    c2h_sim_byp;

   // c2h_csh_byp is used for C2H St Cash Bypass and also C2H MM bypass looback.
   assign c2h_csh_byp = (c2h_dsc_bypass == 2'b01) ? 1'b1 : 1'b0; // 2'b01 : Cache dsc bypass/MM
   assign c2h_sim_byp = (c2h_dsc_bypass == 2'b10) ? 1'b1 : 1'b0; // 2'b10 : Simple dsc_bypass
   
   //c2h_byp_out_fmt == 3'b1 : is marker responce, all other values are reserved

//   assign c2h_st_marker_rsp = c2h_byp_out_rdy & c2h_byp_out_fmt & c2h_byp_out_vld;
   assign c2h_st_marker_rsp = (c2h_byp_out_fmt == 3'b1 ) & c2h_byp_out_vld & ~c2h_byp_out_st_mm;
   assign c2h_mm_marker_rsp = (c2h_byp_out_fmt == 3'b1 ) & c2h_byp_out_vld & c2h_byp_out_st_mm;

   assign c2h_byp_out_rdy        = (c2h_byp_out_fmt == 3'b1) ? 1'b1 :
				   c2h_csh_byp & c2h_byp_out_st_mm ? c2h_byp_in_mm_rdy :
				   c2h_csh_byp & ~c2h_byp_out_st_mm ? c2h_byp_in_st_csh_rdy :
				   c2h_sim_byp & c2h_byp_in_st_csh_rdy;

// MM
   assign c2h_byp_in_mm_mrkr_req = c2h_mm_marker_req;
   assign c2h_byp_in_mm_radr     = c2h_byp_out_dsc[63:0];
   assign c2h_byp_in_mm_wadr     = c2h_byp_out_dsc[191:128];
   assign c2h_byp_in_mm_len      = c2h_byp_out_dsc[79:64];
   assign c2h_byp_in_mm_sdi      = c2h_byp_out_dsc[94];  // eop. send sdi at last desciptor.
   assign c2h_byp_in_mm_qid      = c2h_byp_out_qid;
   assign c2h_byp_in_mm_error    = c2h_byp_out_error;
   assign c2h_byp_in_mm_func     = c2h_byp_out_func;
   assign c2h_byp_in_mm_cidx     = c2h_byp_out_cidx;
   assign c2h_byp_in_mm_port_id  = c2h_byp_out_port_id;
   assign c2h_byp_in_mm_no_dma   = 1'b0;
   assign c2h_byp_in_mm_vld      = c2h_mm_marker_req | (c2h_csh_byp & ~c2h_byp_out_fmt[0] ? c2h_byp_out_st_mm & c2h_byp_out_vld : 1'b0);

//ST Cache/Simple mode
   assign c2h_byp_in_st_csh_addr     = c2h_byp_out_dsc[63:0];
   assign c2h_byp_in_st_csh_qid      = c2h_byp_out_qid;
   assign c2h_byp_in_st_csh_error    = c2h_byp_out_error;
   assign c2h_byp_in_st_csh_func     = c2h_byp_out_func;
   assign c2h_byp_in_st_csh_port_id  = c2h_byp_out_port_id;
   assign c2h_byp_in_st_csh_pfch_tag = c2h_sim_byp ? pfch_byp_tag : c2h_byp_out_pfch_tag;  // for simple bypass use prefetch tag register
   assign c2h_byp_in_st_csh_vld      = c2h_csh_byp | c2h_sim_byp  & ~c2h_byp_out_fmt[0] ? ~c2h_byp_out_st_mm & c2h_byp_out_vld : 1'b0;

endmodule // dsc_bypass

