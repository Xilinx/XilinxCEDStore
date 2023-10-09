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
// File       : ST_h2c_crdt.sv
// Version    : 5.0
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps

/* This module does not produce any data. It is created to do dummy descriptor crediting exchanges
   so the same descriptor crediting module used in C2H can be used here too. If external descriptor
   crediting is not enabled for H2C, then this module is not required.
*/

module ST_h2c_crdt # (
  parameter QID_WIDTH   = 11,                           // Must be 11. Queue ID bit width
  parameter TM_DSC_BITS = 16,                           // Traffic Manager descriptor credit bit width
  parameter TCQ         = 1
) (
  // Global
  input  logic                     user_clk,
  input  logic                     user_reset_n,
  
  // Control Signals
  input  logic [31:0]              knob,             // [31:27] = Amount to batch.
  
  // To queue_cnts
  input  logic [TM_DSC_BITS-1:0]   credit_in,        // Credit available for the given QID
  input  logic [QID_WIDTH-1:0]     qid,              // QID to use in the current transfer
  input  logic                     credit_vld,       // Indicates new QID with non-zero credit is available
  output logic                     credit_rdy,       // Indicates ready to accept next transfer
  output logic [QID_WIDTH-1:0]     dec_qid,          // QID which credit will be decremented
  output logic                     dec_credit,       // Pulsed each time a credit is consumed. Currently set to decrement every 4K to match example design driver behavior
  output logic [QID_WIDTH-1:0]     requeue_qid,      // QID which credit will be requeued
  output logic                     requeue_credit,   // Pulsed each time this QID is done being used
  input  logic                     requeue_rdy,      // When asserted the QID/Credit has been requeued
  
  // To Descriptor Credit Input Logic (if not enabled, then the value is save to ignore)
  output logic [4:0]               dsc_req_val,      // Amount of descriptor to request in a batch. Must assert one clock cycle per request only
  output logic [QID_WIDTH-1:0]     dsc_req_qid,      // QID which credit will be requested
  output logic                     dsc_req_vld       // Valid bit for dsc_req_val
  
);

/* Operation
   When there's a new credit available at the input, decrement them and requeue, one at a time.
*/

logic                       start_gen;                // Start a dummy credit consumer
logic                       start_gen_reg;            // Dec Pipeline register
logic [QID_WIDTH-1:0]       qid_reg;                  // Dec Pipeline register
logic [QID_WIDTH-1:0]       requeue_qid_int[1:0];     // Requeue pipeline stages
logic                       requeue_int_vld[1:0];     // Indicates which requeue pipeline stages are valid
logic [4:0]                 batch_cnt;                // Used to keep track the number of loops when doing batch transfers
logic                       batch_inp;                // Batching in Progress

// Credit Maintainer
always_comb begin
  // Original. Add Batching Support.
//  start_gen      = credit_vld & (~(requeue_int_vld[0] & requeue_int_vld[1])) ? 1'b1 : 1'b0;
//  credit_rdy     = (~(requeue_int_vld[0] & requeue_int_vld[1])) ? 1'b1 : 1'b0;  // Assert ready when a QID is queued up
  start_gen      = (credit_vld & (~(requeue_int_vld[0] & requeue_int_vld[1]))) ? 1'b1 : 1'b0;    // Start generation when descriptor is available and there's a slot open
  credit_rdy     = ((~batch_inp) & (~(requeue_int_vld[0] & requeue_int_vld[1]))) ? 1'b1 : 1'b0;  // Assert ready when a QID is queued up

  // Decrement credit each time a descriptor is consumed (indicated by BYTE_CREDIT or reach tlast)
  dec_credit     = start_gen_reg;
  dec_qid        = qid_reg;

  // Requeue QID once transfer is complete
  requeue_credit = (requeue_int_vld[1] | requeue_int_vld[0]) ? 1'b1 : 1'b0;  // There's something in the buffer needs to be requeued. Always make sure dec_credit occurs first.
  requeue_qid    = requeue_int_vld[1] ? requeue_qid_int[1] : requeue_qid_int[0];
end

// Batching Control Logic
always_ff @(posedge user_clk) begin
  if (~user_reset_n) begin
    batch_cnt     <= #TCQ '0;
    batch_inp     <= #TCQ 1'b0;
    dsc_req_vld   <= #TCQ 1'b0;
  end else begin
    dsc_req_qid   <= #TCQ qid_reg;
    dsc_req_val   <= #TCQ (credit_in >= knob[31:27]) ? knob[31:27] : 1;                     // Copy of max batch_cnt
    dsc_req_vld   <= #TCQ 1'b0;

    if (start_gen) begin // Start packet generation
      if (~batch_inp) begin
        batch_cnt     <= #TCQ (credit_in >= knob[31:27]) ? knob[31:27] : 1;                 // If not enough to do the requested batching, default to just send one.
        batch_inp     <= #TCQ (credit_in >= knob[31:27]) & (knob[31:27] > 1) ? 1'b1 : 1'b0; // Set if we're doing batch requests more than one.
        
        dsc_req_vld   <= #TCQ 1'b1;
      end else begin
        batch_cnt     <= #TCQ batch_cnt - 1;
        batch_inp     <= #TCQ (batch_cnt <= 2) ? 1'b0 : 1'b1; // Last request in the batch
        
        dsc_req_vld   <= #TCQ 1'b0;
      end
    end
  end
end

always_ff @(posedge user_clk) begin
  if (~user_reset_n) begin
    start_gen_reg <= #TCQ 1'b0;
  end else begin
    start_gen_reg <= #TCQ start_gen;
    qid_reg       <= #TCQ (~batch_inp) ? qid : qid_reg;
  end
end

always_ff @(posedge user_clk) begin
  if (~user_reset_n) begin
    requeue_int_vld[0] <= #TCQ 1'b0;
    requeue_int_vld[1] <= #TCQ 1'b0;
  end else begin
    // Requeue QID Buffer
    // If the second slot is empty and we're not waiting for dec_credit, move it there.
    // It's not possible where both requeue_int[1] and requeue_int[0] are asserted and a new transfer comes in
    if (requeue_credit & requeue_rdy) begin
      requeue_int_vld[1]   <= #TCQ (requeue_int_vld[1]) ? requeue_int_vld[0] : 1'b0;
      requeue_qid_int[1]   <= #TCQ requeue_qid_int[0];
  
      if (start_gen_reg) begin // One credit was consumed
        requeue_int_vld[0] <= #TCQ batch_inp ? 1'b0 : 1'b1;
        requeue_qid_int[0] <= #TCQ qid_reg;
      end else begin // No new credit was consumed
        requeue_int_vld[0] <= #TCQ 1'b0;
        requeue_qid_int[0] <= #TCQ requeue_qid_int[0];
      end
    end else begin
      requeue_int_vld[1]   <= #TCQ (~requeue_int_vld[1]) ? requeue_int_vld[0] : requeue_int_vld[1];
      requeue_qid_int[1]   <= #TCQ (~requeue_int_vld[1]) ? requeue_qid_int[0] : requeue_qid_int[1];
    
      if (start_gen_reg) begin // One credit was consumed
        requeue_int_vld[0] <= #TCQ batch_inp ? 1'b0 : 1'b1;
        requeue_qid_int[0] <= #TCQ qid_reg;
      end else begin // No new credit was consumed
        requeue_int_vld[0] <= #TCQ (~requeue_int_vld[1]) ? 1'b0 : requeue_int_vld[0];
        requeue_qid_int[0] <= #TCQ requeue_qid_int[0];
      end
    end // requeue_credit & requeue_rdy
  end
end

endmodule

