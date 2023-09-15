// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
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
