// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////

//
// Project    : The PCI Express DMA 
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
