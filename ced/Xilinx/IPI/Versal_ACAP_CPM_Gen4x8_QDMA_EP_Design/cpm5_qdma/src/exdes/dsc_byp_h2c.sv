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
   input h2c_dsc_bypass,
   input h2c_mm_marker_req,
   input h2c_st_marker_req,
   output h2c_mm_marker_rsp,
   output h2c_st_marker_rsp,
   // Descriptor Bypass Out for mdma
   input  logic [255:0]                                                   h2c_byp_out_dsc,
   input  logic [2:0]                                                     h2c_byp_out_fmt,
   input  logic                                                           h2c_byp_out_st_mm,
   input  logic [1:0]                                                     h2c_byp_out_dsc_sz,
   input  logic [10:0]                                                    h2c_byp_out_qid,
   input  logic                                                           h2c_byp_out_error,
   input  logic [11:0]                                                    h2c_byp_out_func,
   input  logic [15:0]                                                    h2c_byp_out_cidx,
   input  logic [2:0]                                                     h2c_byp_out_port_id,
   input  logic                                                           h2c_byp_out_vld,
   output logic                                                           h2c_byp_out_rdy,
   
   // Desciptor Bypass for mdma 
   output   logic [63:0]                                                    h2c_byp_in_mm_radr,
   output   logic [63:0]                                                    h2c_byp_in_mm_wadr,
   output   logic [15:0]                                                    h2c_byp_in_mm_len,
   output   logic                                                           h2c_byp_in_mm_mrkr_req,
   output   logic                                                           h2c_byp_in_mm_sdi,
   output   logic [10:0]                                                    h2c_byp_in_mm_qid,
   output   logic                                                           h2c_byp_in_mm_error,
   output   logic [11:0]                                                    h2c_byp_in_mm_func,
   output   logic [15:0]                                                    h2c_byp_in_mm_cidx,
   output   logic [2:0]                                                     h2c_byp_in_mm_port_id,
   output   logic                                                           h2c_byp_in_mm_no_dma,
   output   logic                                                           h2c_byp_in_mm_vld,
   input    logic                                                           h2c_byp_in_mm_rdy,

   // Desciptor Bypass for mdma 
   output   logic [63:0]                                                    h2c_byp_in_st_addr,
   output   logic [15:0]                                                    h2c_byp_in_st_len,
   output   logic                                                           h2c_byp_in_st_eop,
   output   logic                                                           h2c_byp_in_st_sop,
   output   logic                                                           h2c_byp_in_st_mrkr_req,
   output   logic                                                           h2c_byp_in_st_sdi,
   output   logic [10:0]                                                    h2c_byp_in_st_qid,
   output   logic                                                           h2c_byp_in_st_error,
   output   logic [11:0]                                                    h2c_byp_in_st_func,
   output   logic [15:0]                                                    h2c_byp_in_st_cidx,
   output   logic [2:0]                                                     h2c_byp_in_st_port_id,
   output   logic                                                           h2c_byp_in_st_no_dma,
   output   logic                                                           h2c_byp_in_st_vld,
   input    logic                                                           h2c_byp_in_st_rdy

   );

   //h2c_byp_out_fmt == 3'b1 : is marker responce, all other values are reserved
   
   assign h2c_mm_marker_rsp = (h2c_byp_out_fmt == 3'b1) & h2c_byp_out_vld & h2c_byp_out_st_mm;
   assign h2c_st_marker_rsp = (h2c_byp_out_fmt == 3'b1) & h2c_byp_out_vld & ~h2c_byp_out_st_mm;

   assign h2c_byp_out_rdy        =  (h2c_byp_out_fmt == 3'b1) ? 1'b1 :
				    h2c_dsc_bypass & h2c_byp_out_st_mm ? h2c_byp_in_mm_rdy : 
				    h2c_dsc_bypass & ~h2c_byp_out_st_mm ? h2c_byp_in_st_rdy : 1'b1;
// MM
   assign h2c_byp_in_mm_mrkr_req = h2c_mm_marker_req;
   assign h2c_byp_in_mm_radr     = h2c_byp_out_dsc[63:0];
   assign h2c_byp_in_mm_wadr     = h2c_byp_out_dsc[191:128];
   assign h2c_byp_in_mm_len      = h2c_byp_out_dsc[79:64];
   assign h2c_byp_in_mm_sdi      = h2c_byp_out_dsc[94];  // eop. send sdi at last discriptor;
   assign h2c_byp_in_mm_qid      = h2c_byp_out_qid;
   assign h2c_byp_in_mm_error    = h2c_byp_out_error;
   assign h2c_byp_in_mm_func     = h2c_byp_out_func;
   assign h2c_byp_in_mm_cidx     = h2c_byp_out_cidx;
   assign h2c_byp_in_mm_port_id  = h2c_byp_out_port_id;
   assign h2c_byp_in_mm_no_dma   = 1'b0;

   assign h2c_byp_in_mm_vld      = h2c_mm_marker_req | (h2c_dsc_bypass & ~h2c_byp_out_fmt[0] ? h2c_byp_out_st_mm & h2c_byp_out_vld : 1'b0);

// ST
   assign h2c_byp_in_st_mrkr_req = h2c_st_marker_req;
   assign h2c_byp_in_st_addr     = h2c_byp_out_dsc[127:64];
   assign h2c_byp_in_st_len      = h2c_byp_out_dsc[47:32];
   assign h2c_byp_in_st_eop      = h2c_byp_out_dsc[49];
   assign h2c_byp_in_st_sop      = h2c_byp_out_dsc[48];
   assign h2c_byp_in_st_sdi      = h2c_byp_out_dsc[49]; // eop. send sdi at last discriptor;
   assign h2c_byp_in_st_qid      = h2c_byp_out_qid;
   assign h2c_byp_in_st_error    = h2c_byp_out_error;
   assign h2c_byp_in_st_func     = h2c_byp_out_func;
   assign h2c_byp_in_st_cidx     = h2c_byp_out_cidx;
   assign h2c_byp_in_st_port_id  = h2c_byp_out_port_id;
   assign h2c_byp_in_st_no_dma   = 1'b0;

   assign h2c_byp_in_st_vld      = h2c_dsc_bypass & ~h2c_byp_out_fmt[0] ? ~h2c_byp_out_st_mm & h2c_byp_out_vld : 1'b0;

endmodule // dsc_bypass

