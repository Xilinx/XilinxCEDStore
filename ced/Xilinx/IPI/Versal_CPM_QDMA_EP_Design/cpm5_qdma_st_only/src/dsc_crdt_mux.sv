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
// File       : dsc_crdt_mux.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

/*
   This module will arbiter Descriptor Credit In interface between C2H and H2C
*/

module dsc_crdt_mux # (
  parameter QID_WIDTH   = 11,                           // Must be 11. Queue ID bit width
  parameter TM_DSC_BITS = 16,                           // Traffic Manager descriptor credit bit width
  parameter TCQ         = 1
) (
  // Global
  input  logic                     user_clk,
  input  logic                     user_reset_n,

  // QDMA Descriptor Credit Bus from C2H Engine
  input  logic [TM_DSC_BITS-1:0]   c2h_dsc_crdt_in_crdt,
  input  logic                     c2h_dsc_crdt_in_dir,
  input  logic                     c2h_dsc_crdt_in_fence,
  input  logic [QID_WIDTH-1:0]     c2h_dsc_crdt_in_qid,
  output logic                     c2h_dsc_crdt_in_rdy,
  input  logic                     c2h_dsc_crdt_in_valid,

  // QDMA Descriptor Credit Bus from H2C Engine
  input  logic [TM_DSC_BITS-1:0]   h2c_dsc_crdt_in_crdt,
  input  logic                     h2c_dsc_crdt_in_dir,
  input  logic                     h2c_dsc_crdt_in_fence,
  input  logic [QID_WIDTH-1:0]     h2c_dsc_crdt_in_qid,
  output logic                     h2c_dsc_crdt_in_rdy,
  input  logic                     h2c_dsc_crdt_in_valid,

  // QDMA Descriptor Credit Bus
  output logic [TM_DSC_BITS-1:0]   dsc_crdt_in_crdt,
  output logic                     dsc_crdt_in_dir,
  output logic                     dsc_crdt_in_fence,
  output logic [QID_WIDTH-1:0]     dsc_crdt_in_qid,
  input  logic                     dsc_crdt_in_rdy,
  output logic                     dsc_crdt_in_valid
);

/* Operation
   If both C2H and H2C credits are available, always arbitrate.
   If only one is available, switch to that one immediately.
   No need to re-buffer the credits as each source has a buffer in them already.
*/

logic sel; // 0=H2C; 1=C2H

always_ff @(posedge user_clk) begin
  if (~user_reset_n) begin
    sel <= #TCQ 1'b0;
  end else begin
    if (c2h_dsc_crdt_in_valid & h2c_dsc_crdt_in_valid) begin
      sel <= #TCQ ~sel;
    end else if (c2h_dsc_crdt_in_valid) begin
      sel <= #TCQ 1'b1;
    end else if (h2c_dsc_crdt_in_valid) begin
      sel <= #TCQ 1'b0;
    end else begin
      sel <= #TCQ sel;
    end
  end
end

always_comb begin
  c2h_dsc_crdt_in_rdy = 1'b0;
  h2c_dsc_crdt_in_rdy = 1'b0;
  if (sel) begin
    dsc_crdt_in_crdt    = c2h_dsc_crdt_in_crdt;
    dsc_crdt_in_dir     = c2h_dsc_crdt_in_dir;
    dsc_crdt_in_fence   = c2h_dsc_crdt_in_fence;
    dsc_crdt_in_qid     = c2h_dsc_crdt_in_qid;
    c2h_dsc_crdt_in_rdy = dsc_crdt_in_rdy;
    dsc_crdt_in_valid   = c2h_dsc_crdt_in_valid;
  end else begin
    dsc_crdt_in_crdt    = h2c_dsc_crdt_in_crdt;
    dsc_crdt_in_dir     = h2c_dsc_crdt_in_dir;
    dsc_crdt_in_fence   = h2c_dsc_crdt_in_fence;
    dsc_crdt_in_qid     = h2c_dsc_crdt_in_qid;
    h2c_dsc_crdt_in_rdy = dsc_crdt_in_rdy;
    dsc_crdt_in_valid   = h2c_dsc_crdt_in_valid;
  end
end

endmodule
