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
// File       : ST_c2h.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

module ST_c2h # (
  parameter DATA_WIDTH  = 64,                   // 64, 128, 256, or 512 bit only
  parameter QID_WIDTH   = 11,                   // Must be 11. Queue ID bit width
  parameter LEN_WIDTH   = 16,                   // Must be 16. 16-bit is the maximum length the interface can handle.
  parameter PATT_WIDTH  = 16,                   // 8 or 16 only. Selects increment counter value every 8 bit or 16 bits
  parameter TM_DSC_BITS = 16,                   // Traffic Manager descriptor credit bit width
  parameter BYTE_CREDIT = 4096,                 // Must be power of 2. Example design driver always issues 4KB descriptor, so we're limiting it to 4KB per credit.
  parameter MAX_CRDT    = 4,                    // Must be power of 2. Maximum number of descriptor allowed in a back to back transfer (to allow other QID to pass)
  parameter QID_MAX     = 64,                   // Number of QID currently enabled in the design. Host may choose to enable less Queue to enable at runtime
  parameter SEED        = 32'hb105f00d,         // rand_num seed
  parameter TCQ         = 1
) (
  // Global
  input                       user_clk,
  input                       user_reset_n,
  
  // Control Signals
  input  [31:0]               knob,             // [0] = Start transfer immediately.
                                                // [1] = Stop transfer immediately.
                                                // [2] = Enable DROP test (not compatible with Simple Bypass).
                                                // [3] = Random BTT.
                                                // [4] = Send Marker.
                                                // [5] = Enable simple bypass (use qid_byp).
                                                // [20:16] = Amount to batch.
                                                // [31:21] = Number of QID to use in DROP case.
  
  // To queue_cnts
  input  [TM_DSC_BITS-1:0]    credit_in,        // Credit available for the given QID
  input  [QID_WIDTH-1:0]      qid,              // QID to use in the current transfer
  input  [QID_WIDTH-1:0]      qid_byp,          // QID to use in the current transfer when simple bypass is enabled. This is going to be the QID for your Prefetch TAG
  input                       credit_vld,       // Indicates new QID with non-zero credit is available
  output                      credit_rdy,       // Indicates ready to accept next transfer
  output reg [QID_WIDTH-1:0]  dec_qid,          // QID which credit will be decremented
  output reg                  dec_credit,       // Pulsed each time a credit is consumed. Currently set to decrement every 4K to match example design driver behavior
  output reg [QID_WIDTH-1:0]  requeue_qid,      // QID which credit will be requeued
  output                      requeue_credit,   // Pulsed each time this QID is done being used
  input                       requeue_rdy,      // When asserted the QID/Credit has been requeued  
  
  output [QID_WIDTH-1:0]      qid_wb,           // QID to send. If !credit_vld, send a packet to random ID, else takes the valid QID input
  output [LEN_WIDTH-1:0]      btt_wb,           // C2H Length to send in Writeback. It must match with the Length of the C2H transfer this Writeback is attached to
  output                      marker_wb,        // C2H packet for this CMPT is a marker packet
  
  input                       cmpt_sent,        // CMPT packet is formed.
  input                       wb_is_full,       // CMPT Bus FIFO is full
  output                      c2h_formed,       // First Beat of C2H
  output                      c2h_fifo_is_full, // C2H Bus FIFO is full

  // To Descriptor Credit Input Logic (if not enabled, then the value is save to ignore)
  output reg [4:0]            dsc_req_val,      // Amount of descriptor to request in a batch. Must assert one clock cycle per request only
  output reg [QID_WIDTH-1:0]  dsc_req_qid,      // QID which credit will be requested
  output reg                  dsc_req_vld,      // Valid bit for dsc_req_val

  // QDMA C2H Bus
  output [DATA_WIDTH-1:0]     c2h_tdata,
  output [LEN_WIDTH-1:0]      c2h_len,
  output [5:0]                c2h_mty,     // This field is a different representation of c2h_len. This is needed for certain QDMA IP version.
  output [QID_WIDTH-1:0]      c2h_qid,
  output                      c2h_marker,  // Used to facilitate pipeline flush during queue invalidation.
  output                      c2h_tlast,
  output                      c2h_tvalid,  // Do not wait for c2h_tready before asserting c2h_tvalid
  input                       c2h_tready,

  input                       cmpt_tvalid,
  input                       cmpt_tready,
  
  input  [LEN_WIDTH-1:0]      dbg_userctrl_credits
);

/* Data consists of the following repeating metadata pattern
|----------------||----------------| First DW
    Byte Index     Byte To Transfer
|--------|-----------|-----------|--| Second DW
   CRC     Random #       QID    CTRL
|--- Repeats First and Second DW ----| DW n

Byte Index              = 16 bits ( in Bytes ) - Current byte index out of the whole transfer
Byte To Transfer        = 16 bits ( in Bytes )
CTRL                    = 2 bits; Use CTRL field to check if the entire First DW and Second DW need to be bit inverted.
                                  Invert as indicated below before using the rest of the data field:
                                  00 = Metadata not inverted
                                  01 = Reserved
                                  10 = Reserved
                                  11 = All bits in Metadata are inverted (except CTRL field)
QID                     = 11 bits ( Queue ID )
Random Number           = 11 bits ( Random Number / Stub )
CRC                     = 8  bits ( CRC )

each CRC bits is an XOR output of 7-bit data on that cycle
CRC[i] = DATA[(i*7)+6] ^ DATA[(i*7)+5] ^ DATA[(i*7)+4] ^ DATA[(i*7)+3] ^ DATA[(i*7)+2] ^ DATA[(i*7)+1] ^ DATA[(i*7)+0];
*/

localparam       HDR_WIDTH        = 64;                            // Must be 64 (must fit within a clock cycle and a multiple of DATA_WIDTH). Length of Metadata in bytes
localparam       INC_DATA         = DATA_WIDTH / PATT_WIDTH;       // Total bytes per beat
localparam       FIFO_TUSER_WIDTH = 1 + QID_WIDTH + 6 + LEN_WIDTH; // Marker + Qid + MTY + Len

localparam       DATA_WIDTH_BYTE  =  (DATA_WIDTH == 64)  ? 8 :
                                    ((DATA_WIDTH == 128) ? 16 :
                                    ((DATA_WIDTH == 256) ? 32 : 64)); // Data Width in Bytes
                 
wire                      start_gen;          // Start Packet Generator
wire                      start_txs;          // Start New Transfer
wire                      sop;                // First Beat of C2H

reg  [2:0]                drop_test_trig;     // Trigger when a DROP case is hit. [0] = Zero Length Transfer. [1] = No credits. [2] = Not Enough credits

reg  [31:0]               rand_num = SEED;    // Random Number
//wire [LEN_WIDTH-1:0]      isel_btt;           // BTT input select. ~knob[3] = dbg_userctrl_credits; knob[3] = rand_num
wire [($clog2(MAX_CRDT * BYTE_CREDIT)-1):0] isel_btt;           // BTT input select. ~knob[3] = dbg_userctrl_credits; knob[3] = rand_num
wire [31:0]               header[1:0];        // Packet header - makes up the Metadata
wire [31:0]               header_raw[1:0];    // Packet header as it goes out in PCIe. Encoded using CTRL field - makes up the Metadata_raw
wire [HDR_WIDTH-1:0]      metadata;           // Packet Metadata prior to encoding
wire [HDR_WIDTH-1:0]      metadata_raw;       // Packet Metadata as it goes out in PCIe. Encoded using CTRL field
wire [(32-8-QID_WIDTH-2)-1:0]   stub;         // Stub
wire [7:0]                crc;                // CRC field for the Metadata
wire [LEN_WIDTH-1:0]      btt;                // Bytes To Transfer
wire [LEN_WIDTH-1:0]      byte_idx;           // Current bytes index/count for the Metadata
wire [1:0]                ctrl;               // Control bits to indicate Metadata bit format
reg  [PATT_WIDTH-1:0]     dat[0:INC_DATA-1];  // Test data pattern
wire [DATA_WIDTH-1:0]     tdata;              // Formed C2H Payload
wire                      ready;              // Test data interface ready signal
reg                       valid;              // Test data pattern valid
reg                       last;               // Test data pattern last
reg  [LEN_WIDTH:0]        byte_ctr;           // Keeps track the number of bytes have been transferred
reg                       marker_sent;        // Indicates marker is sent. No other packet is allowed to be sent until this is reset.
reg  [QID_WIDTH-1:0]      qid_cntr;           // Random ID to be used while !credit_vld.
wire [QID_WIDTH-1:0]      user_avail_qid = knob[31:21];     // User specified number of QID to be used while !credit_vld.

// Pipelines
reg                       mkr_int[1:0];         // C2H Marker pipeline in C2H transfer queue stages
reg [QID_WIDTH-1:0]       qid_int[1:0];         // C2H QID pipeline in C2H transfer queue stages
reg [LEN_WIDTH-1:0]       btt_int[1:0];         // C2H BTT pipeline in C2H transfer queue stages
reg                       int_vld[1:0];         // Indicates which transfer pipeline stages are valid
reg [LEN_WIDTH-1:0]       btt_wrb[1:0];         // C2H BTT pipeline in Writeback transfer queue stages
reg [QID_WIDTH-1:0]       qid_wrb[1:0];         // C2H QID pipeline in Writeback transfer queue stages
reg                       mkr_wrb[1:0];         // C2H Marker pipeline in Writeback transfer queue stages
reg                       wrb_int[1:0];         // Indicates which writeback pipeline stages are valid
reg [QID_WIDTH-1:0]       requeue_qid_int[1:0]; // Requeue pipeline stages
reg                       requeue_int_vld[1:0]; // Indicates which requeue pipeline stages are valid
reg                       rqq_int[1:0];         // Unset when doing batch requests to avoid multiple requeue. Set when we want to requeue at end of batch

// QDMA C2H Bus FIFO
wire [DATA_WIDTH-1:0]     c2h_tdata_fifo_in;
wire [LEN_WIDTH-1:0]      c2h_len_fifo_in;
wire [5:0]                c2h_mty_fifo_in;
wire [QID_WIDTH-1:0]      c2h_qid_fifo_in;
wire                      c2h_marker_fifo_in;
wire                      c2h_tlast_fifo_in;
wire                      c2h_tvalid_fifo_in;  // Do not wait for c2h_tready_fifo_in before asserting c2h_tvalid_fifo_in
wire                      c2h_tready_fifo_in;
wire [FIFO_TUSER_WIDTH-1:0] c2h_tuser_fifo_in;
wire                      c2h_tvalid_fifo_out; // Back-pressure the C2H data until we have enough data to do long burst or is forced to send one
wire                      c2h_tready_fifo_out; // Back-pressure the C2H data until we have enough data to do long burst or is forced to send one
wire [FIFO_TUSER_WIDTH-1:0] c2h_tuser_fifo_out;
wire                      prog_full_axis;      // C2H Bus FIFO is almost full - can only accept one more descriptor worth of data
wire                      almost_empty_axis;   // C2H Bus FIFO is empty

//reg [3:0]                 cmpt_tready_cntr;    // Keep track of how many clock cycles cmpt_tready is low
reg [11:0]                idle_fifo_cntr;      // Keep track of how many clock cycles C2H Bus FIFO has been idling
//wire                      wb_is_full;          // Writeback FIFO in the IP may be full because cmpt_tready has been low for too long
wire                      fifo_idle_timeout;   // C2H Bus FIFO has been idling for too long
wire                      c2h_fifo_start;      // Start dumping C2H Bus FIFO
reg                       c2h_fifo_active;     // Set when C2H Bus FIFO begins transfer and clears only when it's empty
reg [4:0]                 batch_cnt;           // Used to keep track the number of loops when doing batch transfers
reg                       batch_inp;           // Batching in Progress
wire [$clog2(MAX_CRDT):0] txs_desc_amt_raw;    // Number of Descriptor neeeded for one transfer (excluding batches) - Raw values before being adjusted by avail credits.
wire [$clog2(MAX_CRDT):0] txs_desc_amt;        // Number of Descriptor neeeded for one transfer (excluding batches).
reg [4:0]                 dsc_dec_cnt;         // Number of Descriptor to subtract.

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

// Metadata
assign btt           = int_vld[1] ? btt_int[1] : btt_int[0];
assign byte_idx      = byte_ctr - (DATA_WIDTH/8);
assign header[0]     = {byte_idx, btt_int[1]};
assign header[1]     = {crc, stub, qid_int[1], ctrl};
assign metadata      = {header[1], header[0]};
assign header_raw[0] = (ctrl == 2'b00) ? header[0] : (~header[0]);
assign header_raw[1] = (ctrl == 2'b00) ? header[1] : ({~header[1][31:2],ctrl});
assign ctrl          = rand_num[8] ? 2'b00 : 2'b11;    // Randomize bit inversion
assign metadata_raw  = {header_raw[1], header_raw[0]}; // Inversion will exclude CTRL.

// CRC Calculation for the Header
generate
genvar crc_i;
for (crc_i = 0; crc_i < 8; crc_i = crc_i+1) begin
  assign crc[crc_i] = metadata[(crc_i*7)+6] ^ metadata[(crc_i*7)+5] ^ metadata[(crc_i*7)+4] ^ metadata[(crc_i*7)+3] ^ metadata[(crc_i*7)+2] ^ metadata[(crc_i*7)+1] ^ metadata[(crc_i*7)+0];
end
endgenerate

// Stub in unused fields with random number
assign stub = rand_num[0+:(32-8-QID_WIDTH-2)]; // Length is 1DW - 8bit CRC - QID bits - 2bit CTRL

// Append the Metadata at the lower bytes of the first data cycle
assign tdata = (DATA_WIDTH == 64)  ? metadata_raw :
               (DATA_WIDTH == 128) ? {metadata_raw, metadata_raw} :
               (DATA_WIDTH == 256) ? {metadata_raw, metadata_raw, metadata_raw, metadata_raw} :
                                     {metadata_raw, metadata_raw, metadata_raw, metadata_raw, metadata_raw, metadata_raw, metadata_raw, metadata_raw};

// Replaced with FIFO
//assign c2h_tdata  = tdata;
//assign c2h_tlast  = last;
//assign c2h_len    = btt;
//assign c2h_mty    = (last & (c2h_len%(DATA_WIDTH/8) > 0)) ? DATA_WIDTH/8 - (c2h_len%(DATA_WIDTH/8)) : 6'b0;
//assign c2h_tvalid = valid;
//assign ready      = c2h_tready;

assign c2h_tdata_fifo_in  = tdata;
assign c2h_tlast_fifo_in  = last;
assign c2h_len_fifo_in    = btt_int[1];
assign c2h_mty_fifo_in    = (c2h_tlast_fifo_in & (c2h_len_fifo_in%(DATA_WIDTH/8) > 0)) ? DATA_WIDTH/8 - (c2h_len_fifo_in%(DATA_WIDTH/8)) : 6'b0;
assign c2h_qid_fifo_in    = knob[5] ? qid_byp : qid_int[1];
assign c2h_marker_fifo_in = mkr_int[1];
assign c2h_tvalid_fifo_in = valid;
assign ready              = c2h_tready_fifo_in;
assign c2h_tuser_fifo_in  = {c2h_marker_fifo_in, c2h_qid_fifo_in, c2h_mty_fifo_in, c2h_len_fifo_in};
assign {c2h_marker,
        c2h_qid,
        c2h_mty,
        c2h_len}          = c2h_tuser_fifo_out;

// Credit Maintainer
// Decrement credit each time a descriptor is consumed (indicated by BYTE_CREDIT or reach tlast)
/*always @(posedge user_clk) begin
  dec_credit <= #TCQ (byte_ctr == BYTE_CREDIT) | (done[0] == 1);
end*/
//assign dec_credit     = ready & valid & ( ((byte_ctr % BYTE_CREDIT) == 0) | (last == 1) );
//assign dec_qid        = qid_int[1];
always @(posedge user_clk) begin
  if (~user_reset_n) begin
    dec_credit  <= #TCQ 1'b0;
    dsc_dec_cnt <= #TCQ '0;
  end else begin
    if (dsc_req_vld) begin
      dec_credit  <= #TCQ 1'b1;
      dec_qid     <= #TCQ dsc_req_qid;
      dsc_dec_cnt <= #TCQ dsc_req_val;
    end else begin
      dec_credit  <= #TCQ (dsc_dec_cnt <= 1) ? 1'b0 : 1'b1;
      dec_qid     <= #TCQ dec_qid;
      dsc_dec_cnt <= #TCQ (dsc_dec_cnt != 0) ? (dsc_dec_cnt - 1) : 0;
    end
  end
end
// Assert credit_rdy to accept new transfer credits
// Original. Add Batching Support
//assign credit_rdy     = ((~int_vld[0]) | start_txs) ? 1'b1 : 1'b0;  // Assert ready when a QID is queued up
assign credit_rdy     = ((~batch_inp) & ((~int_vld[0]) | start_txs) & (~marker_sent)) ? 1'b1 : 1'b0;  // Assert ready when a QID is queued up and we're done with batching
// Requeue QID once transfer is complete
assign requeue_credit = (requeue_int_vld[1] | (((ready & valid) | (~valid)) & requeue_int_vld[0])) ? 1'b1 : 1'b0;  // Last transfer or there's something in the buffer needs to be requeued. Always make sure dec_credit occurs first.
assign requeue_qid    = requeue_int_vld[1] ? requeue_qid_int[1] : requeue_qid_int[0];

// QID Counter (In Use to send data while there's no credit)
always @(posedge user_clk) begin
  if (~user_reset_n) begin
    qid_cntr     <= #TCQ {QID_WIDTH{1'b0}};
  end else begin // only count up when engine is idling
    if (qid_cntr == (user_avail_qid - 1)) begin  
      qid_cntr   <= #TCQ (credit_rdy & (~credit_vld)) ? {QID_WIDTH{1'b0}} : qid_cntr;
    end else begin
      qid_cntr   <= #TCQ (credit_rdy & (~credit_vld)) ? (qid_cntr + 1) : qid_cntr;
    end
  end
end

// Batching Control Logic
always @(posedge user_clk) begin
  if (~user_reset_n) begin
    batch_cnt     <= #TCQ '0;
    batch_inp     <= #TCQ 1'b0;
    dsc_req_vld   <= #TCQ 1'b0;
  end else begin
    dsc_req_qid   <= #TCQ qid;                                                                                // Only takes QID (not qid_cntr) because it must only request descriptor when there's credit_vld
    dsc_req_val   <= #TCQ (credit_in >= (txs_desc_amt * knob[20:16])) ? (txs_desc_amt * knob[20:16]) : 
                                                                        ((credit_in >= txs_desc_amt) ? txs_desc_amt : 1);
    dsc_req_vld   <= #TCQ 1'b0;
    
    if (start_gen) begin // Start packet generation. // If there's no credit_vld, that means we're doing drop test (knob[2]) which is not supported.
      if ((~batch_inp) & (~knob[4])) begin // Only allow batching if it isn't a marker request. Marker request will not request for descriptor and will only need to be sent once.
        batch_cnt     <= #TCQ (credit_in >= (txs_desc_amt * knob[20:16])) ? knob[20:16] : 1;                  // If not enough to do the requested batching, default to just send one.
        batch_inp     <= #TCQ (credit_in >= (txs_desc_amt * knob[20:16])) & (knob[20:16] > 1) ? 1'b1 : 1'b0;  // Set if we're doing batch requests more than one.
        
        dsc_req_vld   <= #TCQ 1'b1;
      end else begin
        batch_cnt     <= #TCQ batch_inp ? (batch_cnt - 1) : '0;
        batch_inp     <= #TCQ (batch_cnt <= 2) ? 1'b0 : 1'b1; // Last request in the batch
      end
    end
  end
end

always @(*) begin // wire
 rqq_int[0] = ~batch_inp;
end

// Send Writeback
assign c2h_formed = (wrb_int[1] | (((ready & valid) | (~valid)) & wrb_int[0])) ? 1'b1 : 1'b0;
assign qid_wb     = wrb_int[1] ? qid_wrb[1] : qid_wrb[0];
assign btt_wb     = wrb_int[1] ? btt_wrb[1] : btt_wrb[0];
assign marker_wb  = wrb_int[1] ? mkr_wrb[1] : mkr_wrb[0];
// Start packet when there's new request, no active C2H, there's empty CMPT slot, and there's empty requeue slot
assign sop        = (int_vld[0] & (~int_vld[1]) & (~(wrb_int[0] & wrb_int[1])) & (~(requeue_int_vld[0] & requeue_int_vld[1]))) ? 1'b1 : 1'b0;

// Transfer Controller
// Start Engine when there's available transfer credit
// Reset Engine once the desired transfer length has been achieved. It's not necessary to consume all credits available
// int_vld[0] new C2H request
// int_vld[1] current active C2H request
// wrb_int[0] new CMPT
// wrb_int[1] current active CMPT request
// Original. Add Batching Support
//assign start_gen = (credit_rdy & (knob[2] | knob[4] | credit_vld) & (~marker_sent)) ? 1'b1 : 1'b0;
assign start_gen = (((~int_vld[0]) | start_txs) & (knob[2] | knob[4] | credit_vld | batch_inp) & (~marker_sent)) ? 1'b1 : 1'b0;
assign start_txs = (((~valid) | ready) & sop) ? 1'b1 : 1'b0;

assign isel_btt     = knob[3] ? rand_num[0 +: ($clog2(MAX_CRDT * BYTE_CREDIT))] : dbg_userctrl_credits[0 +: ($clog2(MAX_CRDT * BYTE_CREDIT))];

/*--------------------------------------------------------------------   */
// /*Fixing the BYTE_CREDIT to 2048 and desc values are set to 1.
   // This is for timing closure only.
   // With this fix we can not do andy transfers more then 2048 Bytes. */
//assign txs_desc_amt_raw = (|(isel_btt % BYTE_CREDIT)) ? ((isel_btt / BYTE_CREDIT) + 1) : (isel_btt / BYTE_CREDIT); // $ceil(isel_btt / BYTE_CREDIT)
//assign txs_desc_amt = (txs_desc_amt_raw > credit_in) ? 1 : txs_desc_amt_raw;
assign txs_desc_amt_raw = 1; // $ceil(isel_btt / BYTE_CREDIT)
assign txs_desc_amt = 1;

/*--------------------------------------------------------------------   */
   
   
// QID + BTT Pipeline
always @(posedge user_clk) begin
  if (~user_reset_n) begin
    mkr_int[0]     <= #TCQ 1'b0;
    marker_sent    <= #TCQ 1'b0;
    qid_int[0]     <= #TCQ 'h0;
    btt_int[0]     <= #TCQ {LEN_WIDTH{1'b0}};
    int_vld[0]     <= #TCQ 1'b0;
    drop_test_trig <= #TCQ 'h0;
  end else begin
  
    if (start_gen) begin
      // Add Batching Support
      if (~batch_inp) begin
        if (credit_vld) begin
          qid_int[0]    <= #TCQ qid;

          if ( knob[4] ) begin // Marker packet
          
            btt_int[0]    <= #TCQ DATA_WIDTH_BYTE; // Send full bus width
            mkr_int[0]    <= #TCQ 1'b1;
            marker_sent   <= #TCQ 1'b1;
            
          end else if ( txs_desc_amt_raw > credit_in ) begin // Not enough credits or Drop test.
                                                             // Random value return 0, so let's just use up all the credits.
//            btt_int[0]        <= #TCQ (credit_in * BYTE_CREDIT); // Not allowed to consume more than 7 credits - see err_desc_cnt in the PG
            btt_int[0]        <= #TCQ (~knob[2]) ? (1 * BYTE_CREDIT) : isel_btt; // Just send one full credit
            drop_test_trig[0] <= #TCQ (~knob[2]) ? 1'b0 : 1'b1;
            
            mkr_int[0]        <= #TCQ 1'b0;
          end else begin // Enough credit to complete transfer. Limit to MAX_CRDT can be consumed
            btt_int[0]        <= #TCQ isel_btt;
            drop_test_trig[2] <= #TCQ (~knob[2]) ? 1'b0 : 1'b1;
            
            mkr_int[0]    <= #TCQ 1'b0;
          end
        
        end else begin // No credits at all to do transfer
        
          if ( knob[4] ) begin // Marker packet
          
            btt_int[0]    <= #TCQ DATA_WIDTH_BYTE; // Send full bus width
            mkr_int[0]    <= #TCQ 1'b1;
            marker_sent   <= #TCQ 1'b1;
          
          end else begin

            qid_int[0]        <= #TCQ qid_cntr;
            btt_int[0]        <= #TCQ isel_btt;
            drop_test_trig[1] <= #TCQ 1'b1;
          
            mkr_int[0]    <= #TCQ 1'b0;
            
          end
          
        end // credit_vld
      end // ~batch_inp
      
      int_vld[0] <= #TCQ 1'b1;
      
    end else begin
//      if (ready & (~(knob[2] | credit_vld | int_vld[1]))) begin
      if (start_txs) begin
        int_vld[0] <= #TCQ 1'b0;
      end
    end // start_gen
    
    if (marker_sent) begin
      marker_sent <= #TCQ knob[4]; // Reset only when the marker request is released
    end
    
  end // ~user_reset_n
end // always

always @(posedge user_clk) begin
  if (~user_reset_n) begin
     valid         <= #TCQ 1'b0;
     
     int_vld[1]    <= #TCQ 1'b0;
     rqq_int[1]    <= #TCQ 1'b0;
     wrb_int[0]    <= #TCQ 1'b0;
     wrb_int[1]    <= #TCQ 1'b0;
     
     btt_int[1]    <= #TCQ 1'b0;
     mkr_int[1]    <= #TCQ 1'b0;
     
     requeue_int_vld[0] <= #TCQ 1'b0;
     requeue_int_vld[1] <= #TCQ 1'b0;
     
     byte_ctr      <= #TCQ 'h0;
     
  end else begin
    
    // If no active C2H, there's empty CMPT slot, and there's new request
    if (start_txs) begin
    
      if ((DATA_WIDTH/8) >= btt) begin
        last        <= #TCQ 1'b1;
        int_vld[1]  <= #TCQ 1'b0;
      end else begin
        last        <= #TCQ 1'b0;
        int_vld[1]  <= #TCQ 1'b1;
      end
      
      valid         <= #TCQ 1'b1;
      
      qid_int[1]    <= #TCQ qid_int[0];
      btt_int[1]    <= #TCQ btt_int[0];
      mkr_int[1]    <= #TCQ mkr_int[0];
      rqq_int[1]    <= #TCQ rqq_int[0];
      
    end // sop
    
    // If there's active request
    if (ready & int_vld[1]) begin
    
      if ((byte_ctr + (DATA_WIDTH/8)) >= btt) begin
        last        <= #TCQ 1'b1;
        int_vld[1]  <= #TCQ 1'b0;
      end else begin
        last        <= #TCQ 1'b0;
        int_vld[1]  <= #TCQ 1'b1;
      end
      
      valid         <= #TCQ 1'b1;
        
    end //int_vld[1]
    
    if (~(start_txs | int_vld[1] | (~ready))) begin // De-assert Valid when there's no more packet to be sent
      valid <= #TCQ 1'b0;
    end
    
    if (ready & int_vld[1]) begin
      byte_ctr  <= #TCQ byte_ctr + (DATA_WIDTH/8);
    end else if (start_txs) begin
      byte_ctr  <= #TCQ (DATA_WIDTH/8);
    end
    
    // CMPT Buffer
    // If the second slot is empty and we're not waiting for dec_credit, move it there.
    // It's not possible where both wrb_int[0] and wrb_int[1] are asserted and a new transfer comes in
    if (c2h_formed & cmpt_sent) begin
      wrb_int[1]   <= #TCQ (wrb_int[1] & ((ready & valid) | (~valid))) ? wrb_int[0] : 1'b0;
      qid_wrb[1]   <= #TCQ qid_wrb[0];
      btt_wrb[1]   <= #TCQ btt_wrb[0];
      mkr_wrb[1]   <= #TCQ mkr_wrb[0];
    
      if (start_txs & ((DATA_WIDTH/8) >= btt)) begin // One beat transfer completes
        wrb_int[0] <= #TCQ int_vld[0];
        qid_wrb[0] <= #TCQ qid_int[0];
        btt_wrb[0] <= #TCQ btt_int[0];
        mkr_wrb[0] <= #TCQ mkr_int[0];
      end else if ((ready & int_vld[1]) & ((byte_ctr + (DATA_WIDTH/8)) >= btt)) begin // n-beat transfer completes
        wrb_int[0] <= #TCQ int_vld[1];
        qid_wrb[0] <= #TCQ qid_int[1];
        btt_wrb[0] <= #TCQ btt_int[1];
        mkr_wrb[0] <= #TCQ mkr_int[1];
      end else begin // No new transfer completes
//        wrb_int[0] <= #TCQ 1'b0;
        wrb_int[0] <= #TCQ ((ready & valid) | (~valid)) ? 1'b0 : wrb_int[0];
        qid_wrb[0] <= #TCQ qid_wrb[0];
        btt_wrb[0] <= #TCQ btt_wrb[0];
        mkr_wrb[0] <= #TCQ mkr_wrb[0];
      end
    end else begin
      wrb_int[1]   <= #TCQ ((~wrb_int[1]) & ((ready & valid) | (~valid))) ? wrb_int[0] : wrb_int[1];
      qid_wrb[1]   <= #TCQ ((~wrb_int[1]) & ((ready & valid) | (~valid))) ? qid_wrb[0] : qid_wrb[1];
      btt_wrb[1]   <= #TCQ ((~wrb_int[1]) & ((ready & valid) | (~valid))) ? btt_wrb[0] : btt_wrb[1];
      mkr_wrb[1]   <= #TCQ ((~wrb_int[1]) & ((ready & valid) | (~valid))) ? mkr_wrb[0] : mkr_wrb[1];
    
      if (start_txs & ((DATA_WIDTH/8) >= btt)) begin // One beat transfer completes
        wrb_int[0] <= #TCQ int_vld[0];
        qid_wrb[0] <= #TCQ qid_int[0];
        btt_wrb[0] <= #TCQ btt_int[0];
        mkr_wrb[0] <= #TCQ mkr_int[0];
      end else if ((ready & int_vld[1]) & ((byte_ctr + (DATA_WIDTH/8)) >= btt)) begin // n-beat transfer completes
        wrb_int[0] <= #TCQ int_vld[1];
        qid_wrb[0] <= #TCQ qid_int[1];
        btt_wrb[0] <= #TCQ btt_int[1];
        mkr_wrb[0] <= #TCQ mkr_int[1];
      end else begin // No new transfer completes
        wrb_int[0] <= #TCQ ((~wrb_int[1]) & ((ready & valid) | (~valid))) ? 1'b0 : wrb_int[0];
        qid_wrb[0] <= #TCQ qid_wrb[0];
        btt_wrb[0] <= #TCQ btt_wrb[0];
        mkr_wrb[0] <= #TCQ mkr_wrb[0];
      end
    end // cmpt_sent
    
    // Requeue QID Buffer
    // If the second slot is empty and we're not waiting for dec_credit, move it there.
    // It's not possible where both requeue_int[1] and requeue_int[0] are asserted and a new transfer comes in
    if (requeue_credit & requeue_rdy) begin
      requeue_int_vld[1]   <= #TCQ (requeue_int_vld[1] & ((ready & valid) | (~valid))) ? requeue_int_vld[0] : 1'b0;
      requeue_qid_int[1]   <= #TCQ requeue_qid_int[0];
  
      if (start_txs & ((DATA_WIDTH/8) >= btt)) begin // One beat transfer completes
        requeue_int_vld[0] <= #TCQ rqq_int[0] ? int_vld[0] : 1'b0;
        requeue_qid_int[0] <= #TCQ qid_int[0];
      end else if ((ready & int_vld[1]) & ((byte_ctr + (DATA_WIDTH/8)) >= btt)) begin // n-beat transfer completes
        requeue_int_vld[0] <= #TCQ rqq_int[1] ? int_vld[1] : 1'b0;
        requeue_qid_int[0] <= #TCQ qid_int[1];
      end else begin // No new transfer completes
//        requeue_int_vld[0] <= #TCQ 1'b0;
        requeue_int_vld[0] <= #TCQ ((ready & valid) | (~valid)) ? 1'b0 : requeue_int_vld[0];
        requeue_qid_int[0] <= #TCQ requeue_qid_int[0];
      end
    end else begin
      requeue_int_vld[1]   <= #TCQ ((~requeue_int_vld[1]) & ((ready & valid) | (~valid))) ? requeue_int_vld[0] : requeue_int_vld[1];
      requeue_qid_int[1]   <= #TCQ ((~requeue_int_vld[1]) & ((ready & valid) | (~valid))) ? requeue_qid_int[0] : requeue_qid_int[1];
    
      if (start_txs & ((DATA_WIDTH/8) >= btt)) begin // One beat transfer completes
        requeue_int_vld[0] <= #TCQ rqq_int[0] ? int_vld[0] : 1'b0;
        requeue_qid_int[0] <= #TCQ qid_int[0];
      end else if ((ready & int_vld[1]) & ((byte_ctr + (DATA_WIDTH/8)) >= btt)) begin // n-beat transfer completes
        requeue_int_vld[0] <= #TCQ rqq_int[1] ? int_vld[1] : 1'b0;
        requeue_qid_int[0] <= #TCQ qid_int[1];
      end else begin // No new transfer completes
        requeue_int_vld[0] <= #TCQ ((~requeue_int_vld[1]) & ((ready & valid) | (~valid))) ? 1'b0 : requeue_int_vld[0];
        requeue_qid_int[0] <= #TCQ requeue_qid_int[0];
      end
    end // requeue_credit & requeue_rdy

  end
end

// AXI Stream FIFO
// Buffer the packet until the FIFO has a lot
xpm_fifo_axis #(
  .CDC_SYNC_STAGES(2),            // DECIMAL
  .CLOCKING_MODE("common_clock"), // String
  .ECC_MODE("no_ecc"),            // String
  .FIFO_DEPTH(2048),              // DECIMAL
  .FIFO_MEMORY_TYPE("auto"),      // String
  .PACKET_FIFO("false"),          // String
  .PROG_EMPTY_THRESH(1024),       // DECIMAL -- Not used
//  .PROG_FULL_THRESH(2048-(BYTE_CREDIT/DATA_WIDTH)-1), // DECIMAL -- When asserted, FIFO only have spot for one descriptor left.
  .PROG_FULL_THRESH(2048-(4096/(512/8))-1), // DECIMAL -- Hard code value because smaller BYTE_CREDIT makes the limit too high and XPM doesn't support > 2043
//  .PROG_FULL_THRESH(80), // DECIMAL -- Hard code value because smaller BYTE_CREDIT makes the limit too high and XPM doesn't support > 2043
  .RD_DATA_COUNT_WIDTH(11),       // DECIMAL
  .RELATED_CLOCKS(0),             // DECIMAL
  .TDATA_WIDTH(DATA_WIDTH),       // DECIMAL
  .TDEST_WIDTH(1),                // DECIMAL
  .TID_WIDTH(1),                  // DECIMAL
  .TUSER_WIDTH(FIFO_TUSER_WIDTH), // DECIMAL
  .USE_ADV_FEATURES("1E0E"),      // String
  .WR_DATA_COUNT_WIDTH(11)        // DECIMAL
)
xpm_fifo_axis_inst (
  .almost_empty_axis(almost_empty_axis),   // 1-bit output: Almost Empty : When asserted, this signal
                                           // indicates that only one more read can be performed before the
                                           // FIFO goes to empty.

  .almost_full_axis(),                     // 1-bit output: Almost Full: When asserted, this signal
                                           // indicates that only one more write can be performed before
                                           // the FIFO is full.

  .dbiterr_axis(),                         // 1-bit output: Double Bit Error- Indicates that the ECC
                                           // decoder detected a double-bit error and data in the FIFO core
                                           // is corrupted.

  .m_axis_tdata(c2h_tdata),                // TDATA_WIDTH-bit output: TDATA: The primary payload that is
                                           // used to provide the data that is passing across the
                                           // interface. The width of the data payload is an integer number
                                           // of bytes.

  .m_axis_tdest(),                         // TDEST_WIDTH-bit output: TDEST: Provides routing information
                                           // for the data stream.

  .m_axis_tid(),                           // TID_WIDTH-bit output: TID: The data stream identifier that
                                           // indicates different streams of data.

  .m_axis_tkeep(),                         // TDATA_WIDTH-bit output: TKEEP: The byte qualifier that
                                           // indicates whether the content of the associated byte of TDATA
                                           // is processed as part of the data stream. Associated bytes
                                           // that have the TKEEP byte qualifier deasserted are null bytes
                                           // and can be removed from the data stream. For a 64-bit DATA,
                                           // bit 0 corresponds to the least significant byte on DATA, and
                                           // bit 7 corresponds to the most significant byte. For example:
                                           // KEEP[0] = 1b, DATA[7:0] is not a NULL byte KEEP[7] = 0b,
                                           // DATA[63:56] is a NULL byte .

  .m_axis_tlast(c2h_tlast),                // 1-bit output: TLAST: Indicates the boundary of a packet.
  .m_axis_tstrb(),                         // TDATA_WIDTH-bit output: TSTRB: The byte qualifier that
                                           // indicates whether the content of the associated byte of TDATA
                                           // is processed as a data byte or a position byte. For a 64-bit
                                           // DATA, bit 0 corresponds to the least significant byte on
                                           // DATA, and bit 0 corresponds to the least significant byte on
                                           // DATA, and bit 7 corresponds to the most significant byte. For
                                           // example: STROBE[0] = 1b, DATA[7:0] is valid STROBE[7] = 0b,
                                           // DATA[63:56] is not valid .

  .m_axis_tuser(c2h_tuser_fifo_out),       // TUSER_WIDTH-bit output: TUSER: The user-defined sideband
                                           // information that can be transmitted alongside the data
                                           // stream.

  .m_axis_tvalid(c2h_tvalid_fifo_out),     // 1-bit output: TVALID: Indicates that the master is driving a
                                           // valid transfer. A transfer takes place when both TVALID and
                                           // TREADY are asserted .

  .prog_empty_axis(),       // 1-bit output: Programmable Empty- This signal is asserted
                                           // when the number of words in the FIFO is less than or equal to
                                           // the programmable empty threshold value. It is de-asserted
                                           // when the number of words in the FIFO exceeds the programmable
                                           // empty threshold value.

  .prog_full_axis(prog_full_axis),         // 1-bit output: Programmable Full: This signal is asserted when
                                           // the number of words in the FIFO is greater than or equal to
                                           // the programmable full threshold value. It is de-asserted when
                                           // the number of words in the FIFO is less than the programmable
                                           // full threshold value.

  .rd_data_count_axis(), // RD_DATA_COUNT_WIDTH-bit output: Read Data Count- This bus
                                           // indicates the number of words available for reading in the
                                           // FIFO.

  .s_axis_tready(c2h_tready_fifo_in),      // 1-bit output: TREADY: Indicates that the slave can accept a
                                            // transfer in the current cycle.

  .sbiterr_axis(),             // 1-bit output: Single Bit Error- Indicates that the ECC
                                           // decoder detected and fixed a single-bit error.

  .wr_data_count_axis(), // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus
                                           // indicates the number of words written into the FIFO.

  .injectdbiterr_axis(), // 1-bit input: Double Bit Error Injection- Injects a double bit
                                           // error if the ECC feature is used.

  .injectsbiterr_axis(), // 1-bit input: Single Bit Error Injection- Injects a single bit
                                           // error if the ECC feature is used.

  .m_aclk(user_clk),                       // 1-bit input: Master Interface Clock: All signals on master
                                           // interface are sampled on the rising edge of this clock.

  .m_axis_tready(c2h_tready_fifo_out),     // 1-bit input: TREADY: Indicates that the slave can accept a
                                           // transfer in the current cycle.

  .s_aclk(user_clk),                       // 1-bit input: Slave Interface Clock: All signals on slave
                                           // interface are sampled on the rising edge of this clock.

  .s_aresetn(user_reset_n),                // 1-bit input: Active low asynchronous reset.
  .s_axis_tdata(c2h_tdata_fifo_in),        // TDATA_WIDTH-bit input: TDATA: The primary payload that is
                                           // used to provide the data that is passing across the
                                           // interface. The width of the data payload is an integer number
                                           // of bytes.

  .s_axis_tdest('b0),                      // TDEST_WIDTH-bit input: TDEST: Provides routing information
                                           // for the data stream.

  .s_axis_tid('b0),                        // TID_WIDTH-bit input: TID: The data stream identifier that
                                           // indicates different streams of data.

  .s_axis_tkeep({(DATA_WIDTH/8){1'b1}}),   // TDATA_WIDTH-bit input: TKEEP: The byte qualifier that
                                           // indicates whether the content of the associated byte of TDATA
                                           // is processed as part of the data stream. Associated bytes
                                           // that have the TKEEP byte qualifier deasserted are null bytes
                                           // and can be removed from the data stream. For a 64-bit DATA,
                                           // bit 0 corresponds to the least significant byte on DATA, and
                                           // bit 7 corresponds to the most significant byte. For example:
                                           // KEEP[0] = 1b, DATA[7:0] is not a NULL byte KEEP[7] = 0b,
                                           // DATA[63:56] is a NULL byte .

  .s_axis_tlast(c2h_tlast_fifo_in),        // 1-bit input: TLAST: Indicates the boundary of a packet.
  .s_axis_tstrb({(DATA_WIDTH/8){1'b1}}),   // TDATA_WIDTH-bit input: TSTRB: The byte qualifier that
                                           // indicates whether the content of the associated byte of TDATA
                                           // is processed as a data byte or a position byte. For a 64-bit
                                           // DATA, bit 0 corresponds to the least significant byte on
                                           // DATA, and bit 0 corresponds to the least significant byte on
                                           // DATA, and bit 7 corresponds to the most significant byte. For
                                           // example: STROBE[0] = 1b, DATA[7:0] is valid STROBE[7] = 0b,
                                           // DATA[63:56] is not valid .

  .s_axis_tuser(c2h_tuser_fifo_in),        // TUSER_WIDTH-bit input: TUSER: The user-defined sideband
                                           // information that can be transmitted alongside the data
                                           // stream.

  .s_axis_tvalid(c2h_tvalid_fifo_in)       // 1-bit input: TVALID: Indicates that the master is driving a
                                           // valid transfer. A transfer takes place when both TVALID and
                                           // TREADY are asserted .

);

/*
// Writeback ready counter -- Wait for 16 clock cycles
// If Writeback is low for too long, it may indicate that there are too many pending Writebacks.
always @(posedge user_clk) begin
  if (~user_reset_n) begin
    cmpt_tready_cntr <= #TCQ 4'b0;
  end else begin
    if (cmpt_tready) begin
      cmpt_tready_cntr <= #TCQ 4'b0;
    end else if (cmpt_tvalid && (cmpt_tready_cntr != 4'hF)) begin
      cmpt_tready_cntr <= #TCQ cmpt_tready_cntr + 1;
    end else begin
      cmpt_tready_cntr <= #TCQ cmpt_tready_cntr;
    end
  end
end

assign wb_is_full = (cmpt_tready_cntr == 4'hF);
*/

// Idle timeout counter - Wait for 4096 clock cycles
// If no more data is queued, send the stale data in the FIFO over the link
always @(posedge user_clk) begin
  if (~user_reset_n) begin
    idle_fifo_cntr <= #TCQ 12'b0;
  end else begin
    if (c2h_tready_fifo_in & c2h_tvalid_fifo_in) begin
    idle_fifo_cntr <= #TCQ 12'b0;
  end else if (idle_fifo_cntr != 12'hFFF) begin
    idle_fifo_cntr <= #TCQ idle_fifo_cntr + 1;
  end else begin
    idle_fifo_cntr <= #TCQ idle_fifo_cntr;
  end
  end
end

assign fifo_idle_timeout = (idle_fifo_cntr == 12'hFFF);

// C2H Payload FIFO backpressure (do long data burst at the expense of extra latency)
// Send packet when there's data & (fifo hasn't been written for a long time | 
//                                  No more WB is sent for a long time (might be full) |
//                                  Data FIFO is getting full)
// Once data transfer is started, do burst until the FIFO is empty
always @(posedge user_clk) begin
  if (~user_reset_n) begin
    c2h_fifo_active <= #TCQ 1'b0;
  end else begin
    if (almost_empty_axis) begin
      c2h_fifo_active <= #TCQ 1'b0;
    end else if (c2h_tvalid) begin
      c2h_fifo_active <= #TCQ 1'b1;
    end else begin
      c2h_fifo_active <= #TCQ c2h_fifo_active;
    end
  end
end

assign c2h_fifo_start      = (((~almost_empty_axis) & (fifo_idle_timeout | wb_is_full | prog_full_axis)) | knob[0]) ? 1'b1 : 1'b0;
assign c2h_tvalid          = ( (c2h_fifo_start | c2h_fifo_active) && (!knob[1]) ) ? c2h_tvalid_fifo_out : 1'b0;
assign c2h_tready_fifo_out = ( (c2h_fifo_start | c2h_fifo_active) && (!knob[1]) ) ? c2h_tready          : 1'b0;

assign c2h_fifo_is_full    = prog_full_axis;

endmodule

