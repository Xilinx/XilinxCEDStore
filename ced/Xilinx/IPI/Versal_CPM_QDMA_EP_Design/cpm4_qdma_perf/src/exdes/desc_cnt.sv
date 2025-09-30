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
// File       : desc_cnt.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

// calculate the available descriptors for a queue
module desc_cnt #(
  parameter DESC_CNT_WIDTH = 16,
  parameter DESC_AVAIL_WIDTH = 8
) (
  input  wire user_clk,
  input  wire user_reset_n,
  input  wire desc_cnt_inc,
  input  wire [DESC_AVAIL_WIDTH-1:0] desc_inc_val,
  input  wire desc_cnt_dec,
  input  wire desc_cnt_clr,
  output wire [DESC_CNT_WIDTH-1:0] desc_cnt,
  output wire desc_rdy
);

  // register declaration
  reg [DESC_CNT_WIDTH-1:0] descriptor_count;
  reg descriptor_ready;

  // assign outputs
  assign desc_cnt = descriptor_count;
  assign desc_rdy = descriptor_ready & (~((descriptor_count == 1) & desc_cnt_dec));

  // Register if the queue is enabled or disabled
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      descriptor_ready <= 'h0;
    end else begin
      // if the queue is cleared it is no longer ready.
      if (desc_cnt_clr || (descriptor_count == 'h0))
        // descriptor is cleared or descriptor is zero
        descriptor_ready <= 'h0;
      else if ((descriptor_count == 'h1) && !desc_cnt_inc && desc_cnt_dec)
        // descriptor is decrementing to zero
        descriptor_ready <= 1'b0;
      else
        // enable the descriptor
        descriptor_ready <= 1'b1;
    end
  end
  
  // Register the descriptor availability for each queue
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      descriptor_count <= 'h0;
    end else begin
      // increment the credit count
      if (desc_cnt_clr) 
        descriptor_count <= 'h0;
      else if (desc_cnt_inc && (desc_cnt_dec && (descriptor_count != 0)))
        descriptor_count <= descriptor_count + desc_inc_val - 1;
      else if (desc_cnt_inc)
        descriptor_count <= descriptor_count + desc_inc_val;      
      else if (desc_cnt_dec && (descriptor_count != 0))
        descriptor_count <= descriptor_count - 1;
      else
        descriptor_count <= descriptor_count;
    end
  end

endmodule 
