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
// File       : next_queue_fifo.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

// Descriptor Queue FIFO
// This stores all of the queues which are currently enabled
// This is used for the arbitration sequence.
//    FIFO latency 1
//    First-Word-Fall-Through
//    Depth = MAX_QUEUES
//    Width = QUEUE_ID_WIDTH
module next_queue_fifo #(
  parameter QUEUE_ID_WIDTH = 11,
  parameter MAX_QUEUES = 2048
) (
  input  wire user_clk,
  input  wire user_reset_n,
  input  wire [QUEUE_ID_WIDTH-1:0] qid_wr_data,
  input  wire qid_wr_en,
  input  wire qid_rd_en,
  output wire [QUEUE_ID_WIDTH-1:0] qid_rd_data,
  output wire qid_rd_vld
);

   // XPM Syncronous FIFO
   xpm_fifo_sync #(
      .DOUT_RESET_VALUE("0"),    // String
      .ECC_MODE("no_ecc"),       // String
      .FIFO_MEMORY_TYPE("auto"), // String
      .FIFO_READ_LATENCY(1),     // DECIMAL
      .FIFO_WRITE_DEPTH(MAX_QUEUES),   // DECIMAL
      .FULL_RESET_VALUE(0),      // DECIMAL
      .PROG_EMPTY_THRESH(10),    // DECIMAL
      .PROG_FULL_THRESH(10),     // DECIMAL
      .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
      .READ_DATA_WIDTH(QUEUE_ID_WIDTH),      // DECIMAL
      .READ_MODE("fwft"),         // String
      .USE_ADV_FEATURES("1000"), // No flags or count outputs
      .WAKEUP_TIME(0),           // DECIMAL
      .WRITE_DATA_WIDTH(QUEUE_ID_WIDTH),     // DECIMAL
      .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
   xpm_fifo_sync_inst (
      .almost_empty(),   // disabled
      .almost_full(),     // disabled
      .data_valid(qid_rd_vld),       // 1-bit output: Read Data Valid on dout.
      .dbiterr(),             // disabled
      .dout(qid_rd_data),                   // READ_DATA_WIDTH-bit output: Read Data valid when data_valid is asserted.
      .empty(),                 // disabled
      .full(),                   // unused
      .overflow(),           // disabled
      .prog_empty(),       // unused
      .prog_full(),         // disabled
      .rd_data_count(), // disabled
      .rd_rst_busy(),     // 1-bit output: Read Reset Busy, Active-High, FIFO read in reset
      .sbiterr(),             // disabled
      .underflow(),         // disabled
      .wr_ack(),               // disabled
      .wr_data_count(), // disabled
      .wr_rst_busy(),     // 1-bit output: Write Reset Busy, Active-High, FIFO write in reset
      .din(qid_wr_data),                     // WRITE_DATA_WIDTH-bit input: Write Data valid when wr_en is asserted
      .injectdbiterr('b0), // disabled
      .injectsbiterr('b0), // disabled
      .rd_en(qid_rd_en),                 // 1-bit input: Read Enable for the fifo.
      .rst(~user_reset_n),                     // 1-bit input: Reset: Must be synchronous to wr_clk
      .sleep('b0),                 // disabled
      .wr_clk(user_clk),               // 1-bit input: Write clock: Used for write operation
      .wr_en(qid_wr_en)                  // 1-bit input: Write Enable: caused din data to be added to the fifo
   );

endmodule 
