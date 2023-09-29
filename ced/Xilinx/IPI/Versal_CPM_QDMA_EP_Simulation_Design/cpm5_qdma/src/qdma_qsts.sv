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
// File       : qdma_qsts.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps
module qdma_qsts
 (
    input            axi_aresetn,
    input            axi_aclk,
    input [7:0]      qsts_out_op,
    input [63:0]     qsts_out_data,
    input [2:0]      qsts_out_port_id,
    input [12:0]     qsts_out_qid,
    input            qsts_out_vld,
    output           qsts_out_rdy,
    input            c2h_st_marker_req,
    input            c2h_mm_marker_req,
    input            h2c_st_marker_req,
    input            h2c_mm_marker_req,
    output logic     c2h_st_marker_rsp,
    output logic     c2h_mm_marker_rsp,
    output logic     h2c_st_marker_rsp,
    output logic     h2c_mm_marker_rsp
 );
// Marker responce from QSTS interface.
   assign qsts_out_rdy = 1'b1;   // ready is always asserted
   always @(posedge axi_aclk ) begin
      if (~axi_aresetn) begin
         c2h_st_marker_rsp <= 1'b0;
         h2c_st_marker_rsp <= 1'b0;
         c2h_mm_marker_rsp <= 1'b0;
         h2c_mm_marker_rsp <= 1'b0;
         end
      else begin
         c2h_st_marker_rsp <= (c2h_st_marker_req & qsts_out_vld & (qsts_out_op == 8'h0)) ? 1'b1 : ~ c2h_st_marker_req ? 1'b0 : c2h_st_marker_rsp;
         h2c_st_marker_rsp <= (h2c_st_marker_req & qsts_out_vld & (qsts_out_op == 8'h1)) ? 1'b1 : ~ h2c_st_marker_req ? 1'b0 : h2c_st_marker_rsp;
         c2h_mm_marker_rsp <= (c2h_mm_marker_req & qsts_out_vld & (qsts_out_op == 8'h2)) ? 1'b1 : ~ c2h_mm_marker_req ? 1'b0 : c2h_mm_marker_rsp;
         h2c_mm_marker_rsp <= (h2c_mm_marker_req & qsts_out_vld & (qsts_out_op == 8'h3)) ? 1'b1 : ~ h2c_mm_marker_req ? 1'b0 : h2c_mm_marker_rsp;
         end
      end
endmodule
