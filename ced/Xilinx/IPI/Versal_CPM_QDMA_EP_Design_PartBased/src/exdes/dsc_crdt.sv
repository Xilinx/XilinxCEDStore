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
// File       : dsc_crdt.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

/* This module will issue Descriptor Credit to fetch Descriptor based on the Transaction currently generated.
   It monitors which Queue is currently processed by the Data Generator module and issue credits accordingly.
   It does not maintain the credit itself. The crediting interface will be intercepted so we can backpressure Data Generator if FIFO is full.
*/

module dsc_crdt # (
  parameter DIR         = 1,                            // 0=H2C; 1=C2H
  parameter QID_WIDTH   = 11,                           // Must be 11. Queue ID bit width
  parameter TM_DSC_BITS = 16,                           // Traffic Manager descriptor credit bit width
  parameter TCQ         = 1
) (
  // Global
  input  logic                     user_clk,
  input  logic                     user_reset_n,
  
  // Control Signals
  input  [31:0]                    knob,                // [0] = Fence bit.
                                                        // [1] = 1 enables this Descriptor Credit module (QDMA in Simple Bypass mode). Must only toggle bit [1] before any Queue is started

  // To queue_cnts
  input  logic [TM_DSC_BITS-1:0]   qc_credit_in,        // Credit available for the given QID
  input  logic [QID_WIDTH-1:0]     qc_qid,              // QID to use in the current transfer
  input  logic                     qc_credit_vld,       // Indicates new QID with non-zero credit is available
  output logic                     qc_credit_rdy,       // Indicates ready to accept next transfer
  output logic [QID_WIDTH-1:0]     qc_dec_qid,          // QID which credit will be decremented
  output logic                     qc_dec_credit,       // Pulsed each time a credit is consumed. Currently set to decrement every 4K to match example design driver behavior
  output logic [QID_WIDTH-1:0]     qc_requeue_qid,      // QID which credit will be requeued
  output logic                     qc_requeue_credit,   // Pulsed each time this QID is done being used
  input  logic                     qc_requeue_rdy,      // When asserted the QID/Credit has been requeued

  // To Data Generator
  output logic [TM_DSC_BITS-1:0]   dg_credit_in,        // Credit available for the given QID
  output logic [QID_WIDTH-1:0]     dg_qid,              // QID to use in the current transfer
  output logic                     dg_credit_vld,       // Indicates new QID with non-zero credit is available
  input  logic                     dg_credit_rdy,       // Indicates ready to accept next transfer
  input  logic [QID_WIDTH-1:0]     dg_dec_qid,          // QID which credit will be decremented
  input  logic                     dg_dec_credit,       // Pulsed each time a credit is consumed. Currently set to decrement every 4K to match example design driver behavior
  input  logic [QID_WIDTH-1:0]     dg_requeue_qid,      // QID which credit will be requeued
  input  logic                     dg_requeue_credit,   // Pulsed each time this QID is done being used
  output logic                     dg_requeue_rdy,      // When asserted the QID/Credit has been requeued
  
  // From Traffic Generator Logic (if not enabled, then the value is save to ignore)
  input  logic [4:0]               dsc_req_val,         // Amount of descriptor to request in a batch. Must assert one clock cycle per request only
  input  logic [QID_WIDTH-1:0]     dsc_req_qid,         // QID which credit will be requested
  input  logic                     dsc_req_vld,         // Valid bit for dsc_req_val

  // QDMA Descriptor Credit Bus
  output logic [TM_DSC_BITS-1:0]   dsc_crdt_in_crdt,
  output logic                     dsc_crdt_in_dir,
  output logic                     dsc_crdt_in_fence,
  output logic [QID_WIDTH-1:0]     dsc_crdt_in_qid,
  input  logic                     dsc_crdt_in_rdy,
  output logic                     dsc_crdt_in_valid
);

/* Operation
   Monitor the dec_qid and dec_credit. Each pulse of this signal indicates one descriptor is being consumed by the Data Generator.
   Issue the Descriptor Credit to fetch the Descriptor in the same order as the Data.
   Throttle the Data Generator if the Descriptor Credit interface is backed up.
*/

logic [QID_WIDTH+5-1:0] fifo_dout, fifo_din;
logic                   fifo_data_valid, fifo_rd_en, fifo_wr_en;
logic                   fifo_empty, fifo_full, fifo_prog_full;

// Instantiate a shallow FIFO to absorb backpressure on the Descriptor Credit interface before throttling the Data Generator.
xpm_fifo_sync #(
  .CASCADE_HEIGHT(0),           // DECIMAL
  .DOUT_RESET_VALUE("0"),       // String
  .ECC_MODE("no_ecc"),          // String
  .FIFO_MEMORY_TYPE("auto"),    // String
  .FIFO_READ_LATENCY(1),        // DECIMAL
  .FIFO_WRITE_DEPTH(16),        // DECIMAL - minimum 16 for XPM
  .FULL_RESET_VALUE(0),         // DECIMAL
  .PROG_EMPTY_THRESH(5),        // DECIMAL
  .PROG_FULL_THRESH(11),        // DECIMAL
  .RD_DATA_COUNT_WIDTH(1),      // DECIMAL
  .READ_DATA_WIDTH(QID_WIDTH +5),  // DECIMAL // QID_WIDTH + Batch Value
  .READ_MODE("fwft"),           // String
  .SIM_ASSERT_CHK(0),           // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
  .USE_ADV_FEATURES("1002"),    // String  - Enable data_valid
  .WAKEUP_TIME(0),              // DECIMAL
  .WRITE_DATA_WIDTH(QID_WIDTH +5), // DECIMAL // QID_WIDTH + Batch Value
  .WR_DATA_COUNT_WIDTH(1)       // DECIMAL
)
xpm_fifo_sync_inst (
  .almost_empty(),               // 1-bit output: Almost Empty : When asserted, this signal indicates that
                                 // only one more read can be performed before the FIFO goes to empty.

  .almost_full(),                // 1-bit output: Almost Full: When asserted, this signal indicates that
                                 // only one more write can be performed before the FIFO is full.

  .data_valid(fifo_data_valid),  // 1-bit output: Read Data Valid: When asserted, this signal indicates
                                 // that valid data is available on the output bus (dout).

  .dbiterr(),                    // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
                                 // a double-bit error and data in the FIFO core is corrupted.

  .dout(fifo_dout),              // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                                 // when reading the FIFO.

  .empty(fifo_empty),            // 1-bit output: Empty Flag: When asserted, this signal indicates that the
                                 // FIFO is empty. Read requests are ignored when the FIFO is empty,
                                 // initiating a read while empty is not destructive to the FIFO.

  .full(fifo_full),              // 1-bit output: Full Flag: When asserted, this signal indicates that the
                                 // FIFO is full. Write requests are ignored when the FIFO is full,
                                 // initiating a write when the FIFO is full is not destructive to the
                                 // contents of the FIFO.

  .overflow(),                   // 1-bit output: Overflow: This signal indicates that a write request
                                 // (wren) during the prior clock cycle was rejected, because the FIFO is
                                 // full. Overflowing the FIFO is not destructive to the contents of the
                                 // FIFO.

  .prog_empty(),                 // 1-bit output: Programmable Empty: This signal is asserted when the
                                 // number of words in the FIFO is less than or equal to the programmable
                                 // empty threshold value. It is de-asserted when the number of words in
                                 // the FIFO exceeds the programmable empty threshold value.

  .prog_full(fifo_prog_full),    // 1-bit output: Programmable Full: This signal is asserted when the
                                 // number of words in the FIFO is greater than or equal to the
                                 // programmable full threshold value. It is de-asserted when the number of
                                 // words in the FIFO is less than the programmable full threshold value.

  .rd_data_count(),              // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the
                                 // number of words read from the FIFO.

  .rd_rst_busy(),                // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read
                                 // domain is currently in a reset state.

  .sbiterr(),                    // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected
                                 // and fixed a single-bit error.

  .underflow(),                  // 1-bit output: Underflow: Indicates that the read request (rd_en) during
                                 // the previous clock cycle was rejected because the FIFO is empty. Under
                                 // flowing the FIFO is not destructive to the FIFO.

  .wr_ack(),                     // 1-bit output: Write Acknowledge: This signal indicates that a write
                                 // request (wr_en) during the prior clock cycle is succeeded.

  .wr_data_count(),              // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                 // the number of words written into the FIFO.

  .wr_rst_busy(),                // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                 // write domain is currently in a reset state.

  .din(fifo_din),                // WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                                 // writing the FIFO.

  .injectdbiterr(1'b0),          // 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                 // the ECC feature is used on block RAMs or UltraRAM macros.

  .injectsbiterr(1'b0),          // 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                 // the ECC feature is used on block RAMs or UltraRAM macros.

  .rd_en(fifo_rd_en),            // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                                 // signal causes data (on dout) to be read from the FIFO. Must be held
                                 // active-low when rd_rst_busy is active high.

  .rst(~user_reset_n),           // 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
                                 // unstable at the time of applying reset, but reset must be released only
                                 // after the clock(s) is/are stable.

  .sleep(1'b0),                  // 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo
                                 // block is in power saving mode.

  .wr_clk(user_clk),             // 1-bit input: Write clock: Used for write operation. wr_clk must be a
                                 // free running clock.

  .wr_en(fifo_wr_en)             // 1-bit input: Write Enable: If the FIFO is not full, asserting this
                                 // signal causes data (on din) to be written to the FIFO Must be held
                                 // active-low when rst or wr_rst_busy or rd_rst_busy is active high
);

always_comb begin
  // Note that we technically shouldn't issue Credit if the Queue is invalid (as per the PG), however implementing a check is expensive
  // and slows down Queue processing, so we will assume that Host driver is controlled and will not de-allocate a Queue mid-transfer.
  dsc_crdt_in_crdt         = fifo_dout[4:0];
  dsc_crdt_in_dir          = DIR;
//  dsc_crdt_in_fence        = 1'b1;       // Set the fence bit to avoid coalescing credits and make sure the descriptor is fetched in the order of data generated
  dsc_crdt_in_fence        = knob[0];
  dsc_crdt_in_qid          = fifo_dout[5+:QID_WIDTH];
  dsc_crdt_in_valid        = (~knob[1]) ? 1'b0 : fifo_data_valid;
  
  fifo_rd_en               = fifo_data_valid & dsc_crdt_in_rdy;
  fifo_wr_en               = dsc_req_vld; // Not checking for Full. That condition must never occur (throttle Data Generator before it is full)
  fifo_din                 = {dsc_req_qid, dsc_req_val};
end

logic credit_vld_hold; // Used to keep Valid asserted until Ready comes
always_ff @(posedge user_clk) begin
  if (~user_reset_n) begin
    credit_vld_hold <= #TCQ 1'b0;
  end else begin
    if (dg_credit_vld & (~qc_credit_rdy)) begin
      credit_vld_hold <= #TCQ 1'b1;
    end else if (qc_credit_rdy) begin
      credit_vld_hold <= #TCQ 1'b0;
    end else begin
      credit_vld_hold <= #TCQ credit_vld_hold;
    end
  end
end
// Pass-through most signals except put a throttle on the credit_in signal if the Descriptor Credit interface is falling behind.
// If Data Generator is already started when we need to throttle, make sure it only de-assert vld when rdy has came back (vld cannot de-assert mid-transfer).
always_comb begin
  dg_credit_in      = qc_credit_in;
  dg_qid            = qc_qid;
  dg_credit_vld     = ((~knob[1]) | (~fifo_prog_full)) ? qc_credit_vld : credit_vld_hold;
  qc_credit_rdy     = ((~knob[1]) | (~fifo_prog_full)) ? dg_credit_rdy : (credit_vld_hold ? dg_credit_rdy : 1'b0);
  
  qc_dec_qid        = dg_dec_qid;
  qc_dec_credit     = dg_dec_credit;
  
  qc_requeue_qid    = dg_requeue_qid;
  qc_requeue_credit = dg_requeue_credit;
  dg_requeue_rdy    = qc_requeue_rdy;
end

endmodule

