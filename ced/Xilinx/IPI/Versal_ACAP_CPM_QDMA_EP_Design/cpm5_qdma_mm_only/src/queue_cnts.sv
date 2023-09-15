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

// Module tracks the descriptor counts for each queue as provided on the traffic manager interface. 
//    Supports invalidate
//    Supports queue availability updates

module queue_cnts #(
  parameter DIR            = 1,   // 0=H2C; 1=C2H
  parameter DESC_CNT_WIDTH = 16,
  parameter DESC_AVAIL_WIDTH = 8,
  parameter MAX_QUEUES = 128,
  parameter QUEUE_ID_WIDTH = 7,
  parameter SEED = 32'hb105f00d,    // rand_num seed
  parameter TCQ = 1
) (
  input  wire user_clk,
  input  wire user_reset_n,

  // tm interface signals
  input  wire tm_dsc_sts_vld,
  input  wire tm_dsc_sts_qen,
  input  wire tm_dsc_sts_byp, // 0=desc fetched from host; 1=desc came from descriptory bypass
  input  wire tm_dsc_sts_dir, // 0=H2C; 1=C2H
  input  wire tm_dsc_sts_mm, // 0=ST; 1=MM
  input  wire [QUEUE_ID_WIDTH-1:0] tm_dsc_sts_qid, // QID for update
  input  wire [DESC_AVAIL_WIDTH-1:0] tm_dsc_sts_avl, // Number of new descriptors since last update
  input  wire tm_dsc_sts_qinv, // 1 indicated to invalidate the queue
  input  wire tm_dsc_sts_irq_arm, // 1 indicated to that the driver is using interrupts
  output wire tm_dsc_sts_rdy, // 1 indicates valid data on the bus

  // Re Queue interface. Assert enable and provide the qid you want requeued.
  // This will only requeue IDs that are not already in the queue.
  input  wire                      requeue_vld,
  input  wire [QUEUE_ID_WIDTH-1:0] requeue_qid,
  output wire                      requeue_rdy,

  // Descriptor count decrement interface. Assert the _dec signal with the appropriate QID
  // to decrement the descriptor count by 1.
  input  wire desc_cnt_dec, // decrement the quid count by 1
  input  wire [QUEUE_ID_WIDTH-1:0] desc_cnt_dec_qid, // qid for desc_cnt_dec signal

  //  output wire qid_valid, // valid output for the next queue id
  input  wire qid_rdy, // ready for the next queue id
                  output reg qid_vld, // current qid and availabilyt is valid.
  output reg [QUEUE_ID_WIDTH-1:0] qid,
  output reg [DESC_CNT_WIDTH-1:0] qid_desc_avail,

  // tmsts throttle/backpresure signals
  input wire back_pres,
  input wire turn_off
);

  // wire declares
  wire desc_cnt_inc_comb;
  wire desc_cnt_clr_comb;
  reg  [MAX_QUEUES-1:0] qid_onehot;
  reg  [QUEUE_ID_WIDTH-1:0] qid_encoded;
  reg  desc_cnt_inc;
  reg  [DESC_AVAIL_WIDTH-1:0] desc_inc_val;
  reg  desc_cnt_clr;
  wire [DESC_CNT_WIDTH-1:0] desc_cnt [MAX_QUEUES-1:0];
  wire [MAX_QUEUES-1:0] desc_rdy;

  wire tm_add_queue_comb;
  wire reuse_add_queue_comb;
  reg  [QUEUE_ID_WIDTH-1:0] qid_wr_data;
  reg  qid_wr_en;
  wire qid_rd_en;

  wire [QUEUE_ID_WIDTH-1:0] qid_rd_data;
  wire qid_rd_valid;

  reg  [MAX_QUEUES-1:0] queued_ids;

  reg  [MAX_QUEUES-1:0] desc_cnt_dec_qid_onehot;
  reg  desc_cnt_dec_reg;
  
  wire                      tm_dsc_sts_rdy_throttle;
  reg  [31:0]               rand_num = SEED;    // Random Number
  
  reg                       requeue_vld_reg;
  reg  [QUEUE_ID_WIDTH-1:0] requeue_qid_reg;
  
  // Random Number Generator
  always @(posedge user_clk) begin
    rand_num[0] <= #TCQ rand_num[31];
    rand_num[1] <= #TCQ rand_num[0] ^ rand_num[0];
    rand_num[2] <= #TCQ rand_num[1] ^ rand_num[0];
    rand_num[3] <= #TCQ rand_num[2] ^ rand_num[0];
    rand_num[4] <= #TCQ rand_num[3] ^ rand_num[0];
    rand_num[5] <= #TCQ rand_num[4] ^ rand_num[0];
    rand_num[6] <= #TCQ rand_num[5] ^ rand_num[0];
    rand_num[7]  <= #TCQ rand_num[6];
    rand_num[8]  <= #TCQ rand_num[7];
    rand_num[9]  <= #TCQ rand_num[8];
    rand_num[10] <= #TCQ rand_num[9];
    rand_num[11] <= #TCQ rand_num[10];
    rand_num[12] <= #TCQ rand_num[11];
    rand_num[13] <= #TCQ rand_num[12];
    rand_num[14] <= #TCQ rand_num[13];
    rand_num[15] <= #TCQ rand_num[14];
    rand_num[16] <= #TCQ rand_num[15] ^ rand_num[1];
    rand_num[17] <= #TCQ rand_num[16] ^ rand_num[1];
    rand_num[18] <= #TCQ rand_num[17] ^ rand_num[1];
    rand_num[19] <= #TCQ rand_num[18] ^ rand_num[1];
    rand_num[20] <= #TCQ rand_num[19] ^ rand_num[1];
    rand_num[21] <= #TCQ rand_num[20] ^ rand_num[1];
    rand_num[22] <= #TCQ rand_num[21] ^ rand_num[1];
    rand_num[23] <= #TCQ rand_num[22] ^ rand_num[1];
    rand_num[24]  <= #TCQ rand_num[23];
    rand_num[25]  <= #TCQ rand_num[24];
    rand_num[26]  <= #TCQ ~rand_num[25];
    rand_num[27]  <= #TCQ ~rand_num[26];
    rand_num[28]  <= #TCQ ~rand_num[27];
    rand_num[29]  <= #TCQ ~rand_num[28];
    rand_num[30]  <= #TCQ ~rand_num[29];
    rand_num[31]  <= #TCQ ~rand_num[30];
  end

  assign tm_dsc_sts_rdy_throttle = (back_pres & rand_num[8]) ? 1'b1 : turn_off;
  assign tm_dsc_sts_rdy = tm_dsc_sts_rdy_throttle ? 1'b0 : 1'b1;

  // Strobe for when the descriptor count should increment (filter on stream, c2h transactions)
  assign desc_cnt_inc_comb = tm_dsc_sts_qen & tm_dsc_sts_vld & tm_dsc_sts_rdy & ~tm_dsc_sts_mm & (tm_dsc_sts_dir == DIR);
  // Strobe for when the descriptor count should be cleared (independent of stream or c2h)
  assign desc_cnt_clr_comb = (tm_dsc_sts_qinv | (~tm_dsc_sts_qen)) & tm_dsc_sts_vld & tm_dsc_sts_rdy;
  // Register input values as needed
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      qid_onehot <= 'h0;
      qid_encoded <= 'h0;
      desc_cnt_inc <= 'h0;
      desc_inc_val <= 'h0;
      desc_cnt_clr <= 'h0;
    end else begin
      // Decode the queue id
      qid_onehot <= 'h1 << tm_dsc_sts_qid;
      qid_encoded <= tm_dsc_sts_qid;
      // Calculate the increment signal We only increment on ST and C2H
      desc_cnt_inc <= desc_cnt_inc_comb;
      // Register the available signal
      desc_inc_val <= tm_dsc_sts_avl;
      // Register the clear value
      desc_cnt_clr <= desc_cnt_clr_comb;
    end
  end

  // Generate Descriptor counter for each queue
  genvar j;
  generate
    for (j = 0; j < MAX_QUEUES; j=j+1) begin : desc_cnt_inst
      // add a descriptor count module for each queue
      desc_cnt    #(
        .DESC_CNT_WIDTH(DESC_CNT_WIDTH),
        .DESC_AVAIL_WIDTH(DESC_AVAIL_WIDTH)
      ) desc_cnt_inst (
        .user_clk(user_clk),
        .user_reset_n(user_reset_n),
        .desc_cnt_inc(qid_onehot[j] & desc_cnt_inc),
        .desc_inc_val(desc_inc_val),
        .desc_cnt_dec(desc_cnt_dec_qid_onehot[j] & desc_cnt_dec_reg),
        .desc_cnt_clr(qid_onehot[j] & desc_cnt_clr),
        .desc_cnt(desc_cnt[j]),
        .desc_rdy(desc_rdy[j])
      );
    end
  endgenerate

  // FIFO Read Enable Interface
  assign qid_rd_en = ~qid_vld || (qid_vld & qid_rdy);
  // Write interface for the queue id fifo
  // Add a tm_* id when needed.
  assign tm_add_queue_comb = desc_cnt_inc & ((~queued_ids[qid_encoded]) | ((qid_encoded == qid_rd_data) & (qid_rd_valid & qid_rd_en & ~desc_rdy[qid_rd_data])));
  // Any time the tm_* interface is adding to the queue FIFO the requeue interface must be back pressured.
  assign requeue_rdy = ~tm_add_queue_comb;
  // Add a queue id when the descriptor has been process if not already added and is still enabled.
//  assign reuse_add_queue_comb = requeue_vld & requeue_rdy & ~queued_ids[requeue_qid] & desc_rdy[requeue_qid];
  assign reuse_add_queue_comb = requeue_vld_reg & requeue_rdy & desc_rdy[requeue_qid_reg];
  // Create the qid fifo write enable and write data signals.
  // tmsts interface takes precedence and is never back pressured over the requeue interface.
  always @* begin
    if (tm_add_queue_comb) begin
      // Queue a new ID from tm_* interface
      qid_wr_data <= qid_encoded;
      qid_wr_en <= 1'b1;
    end else if (reuse_add_queue_comb) begin
      // Re queue a used ID
      qid_wr_data <= requeue_qid_reg;
      qid_wr_en <= 1'b1;
    end else begin
      // Wait for next ID
      qid_wr_data <= qid_encoded;
      qid_wr_en <= 1'b0;
    end
  end

  // FIFO to store the queue IDs that are enabled.
  next_queue_fifo #(
    .QUEUE_ID_WIDTH(QUEUE_ID_WIDTH),
    .MAX_QUEUES(MAX_QUEUES)
  ) qid_fifo_i (
    .user_clk(user_clk),
    .user_reset_n(user_reset_n),
    .qid_wr_data(qid_wr_data),
    .qid_wr_en(qid_wr_en),
    .qid_rd_en(qid_rd_en),
    .qid_rd_data(qid_rd_data),
    .qid_rd_vld(qid_rd_valid)
  );

  // Track if the queue ID is already queued in the queue fifo
  always @(posedge user_clk) begin
    // default value is to retain contents.
    queued_ids <= queued_ids;
    if (!user_reset_n) begin
      queued_ids <= 'h0;
    end else begin
      //if (qid_rd_valid & qid_rd_en) begin
      if (requeue_vld_reg & requeue_rdy & ~desc_rdy[requeue_qid_reg]) begin
//      if (~reuse_add_queue_comb) begin
        // unset the corresponding bit anytime the fifo is read
        queued_ids[requeue_qid_reg] <= 1'b0;
      end
      // FIFO Drop
      if (qid_rd_valid & qid_rd_en & ~desc_rdy[qid_rd_data]) begin
        queued_ids[qid_rd_data] <= 1'b0;
      end
      if (qid_wr_en) begin
        // set the corresponding bit anytime the fifo is written
        // Note: that writing the fifo takes precidence because of
        // the latency through the FIFO.
        queued_ids[qid_wr_data] <= 1'b1;
      end
    end
  end  

  // convert the dec_qid signal to onehot and register it
  // register the corresponding enable
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      desc_cnt_dec_qid_onehot <= 'h0;
      desc_cnt_dec_reg <= 'h0;
    end else begin
      desc_cnt_dec_qid_onehot <= 1'b1 << desc_cnt_dec_qid;
      desc_cnt_dec_reg <= desc_cnt_dec;
    end
  end

  // Register the QID output interface
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      qid <= 'h0;
      qid_desc_avail <= 'h0;
      qid_vld <= 'h0;
    end else begin
      // Replace the contents of the output register when
      //   1) The output register doesn't have valid data (FIFO may or maynot have valid data)
      //   2) The output register has valid data and the users ready is asserted
      if (qid_rd_en) begin
        qid_vld <= qid_rd_valid & desc_rdy[qid_rd_data];
        qid <= qid_rd_data;
        qid_desc_avail <= desc_cnt[qid_rd_data];
      end else begin
        qid_vld <= qid_vld;
        qid <= qid;
        qid_desc_avail <= qid_desc_avail;
      end
    end
  end
  
  always @(posedge user_clk) begin
    if (!user_reset_n) begin
      requeue_vld_reg <= #TCQ 1'b0;
      requeue_qid_reg <= #TCQ 'h0;
    end else begin
      requeue_vld_reg <= #TCQ requeue_rdy ? requeue_vld : requeue_vld_reg;
      requeue_qid_reg <= #TCQ requeue_rdy ? requeue_qid : requeue_qid_reg;
    end
  end

endmodule 
