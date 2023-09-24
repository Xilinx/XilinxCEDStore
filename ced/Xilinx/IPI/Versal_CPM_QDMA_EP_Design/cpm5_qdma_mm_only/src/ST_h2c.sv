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

//
// Stream H2C
//
module ST_h2c # (
  parameter DATA_WIDTH  = 64,              // 64, 128, 256, or 512 bit only
  parameter QID_WIDTH   = 11,              // Must be 11. Queue ID bit width
  parameter LEN_WIDTH   = 16,              // Must be 16. 16-bit is the maximum length the interface can handle.
  parameter PATT_WIDTH  = 16,              // 8 or 16 only. Selects increment counter value every 8 bit or 16 bits
  parameter TM_DSC_BITS = 16,              // Traffic Manager descriptor credit bit width
  parameter BYTE_CREDIT = 4096,            // Must be power of 2. Example design driver always issues 4KB descriptor, so we're limiting it to 4KB per credit.
  parameter MAX_CRDT    = 4,               // Must be power of 2. Maximum number of descriptor allowed in a back to back transfer (to allow other QID to pass)
  parameter SEED        = 32'hb105f00d,    // rand_num seed
  parameter TCQ         = 1
) (
  // Global
  input                       user_clk,
  input                       user_reset_n,

  // Control Signals
  input  [31:0]               knob,  
  // Status Signals
  output                      stat_vld,
  output [31:0]               stat_err,
  
  // QDMA H2C Bus
  input  [DATA_WIDTH-1:0]     h2c_tdata,
  input  [(DATA_WIDTH/8)-1:0] h2c_dpar,
  input                       h2c_tlast,
  input                       h2c_tvalid,
  output reg                  h2c_tready,
  input  [QID_WIDTH-1:0]      h2c_tuser_qid,
  input  [2:0]                h2c_tuser_port_id,
  input                       h2c_tuser_err,
  input  [31:0]               h2c_tuser_mdata,
  input  [5:0]                h2c_tuser_mty,
  input                       h2c_tuser_zero_byte
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

localparam       HDR_WIDTH = 64;                      // Must be 64 (must fit within a clock cycle and a multiple of DATA_WIDTH). Length of Metadata in bytes
localparam       INC_DATA  = DATA_WIDTH / PATT_WIDTH; // Total bytes per beat

reg  [31:0]               rand_num = SEED;    // Random Number
wire [31:0]               header[1:0];        // Packet header - makes up the Metadata
wire [HDR_WIDTH-1:0]      metadata;           // Decoded packet Metadata using CTRL field
wire [HDR_WIDTH-1:0]      metadata_raw;       // Packet Metadata as it comes in
wire [7:0]                crc;                // CRC field from the Metadata
wire [LEN_WIDTH-1:0]      btt;                // Bytes to transfer from the Metadata
wire [LEN_WIDTH-1:0]      byte_idx;           // Current bytes index/count from the Metadata
wire [1:0]                ctrl;               // Control bits to indicate Metadata bit format
wire [(DATA_WIDTH/8)-1:0] dpar;               // Parity calculation
wire [7:0]                exp_crc;            // CRC field calculation
wire [QID_WIDTH-1:0]      exp_qid;            // Expected QID field from the Metadata
wire                      bad_metadata;       // Incomplete Metadata due to transfer beat shorter than HDR_WIDTH

reg  [PATT_WIDTH-1:0]     dat[0:INC_DATA-1];  // Test data pattern
reg  [DATA_WIDTH-1:0]     h2c_tdata_nonmty;   // h2c_tdata without the mty signal (fill in the empty bytes with good data, for easier data pattern checking)
reg  [LEN_WIDTH-1:0]      h2c_len;            // Actual received data length on h2c_tdata
reg                       pcie_err_ored;      // Sticky between sop and eop. OR reduced of pcie_err
reg                       crc_err, par_err;   // Sticky between sop and eop. Metadata CRC error or h2c_dpar error
reg                       dat_64B_err;        // Sticky between sop and eop. Expected data is repeating every 64B, set when they're not equal
reg                       len_err;            // Sticky between sop and eop. Data length in metadata doesn't match actual data length
reg                       qid_err;            // Sticky between sop and eop. QID in metadata doesn't match actual qid

reg                       h2c_busy;           // Data transfer in progress; between sop and eop
reg                       h2c_busy_reg;       // Registered version of h2c_busy
wire                      back_pres;          // 1= randomly deasserts h2c_tready to create backpressure. 0= Normal operation (keep ready high as long as possible)
wire                      lossy;              // 1= Allow lossy data transfer (packet may not start at Byte Index 0 or receive enough data to match Metadata)
                                              // 0= Lossless data transfer. Received packet count must be exactly as indicated in Metadata
                                              
reg  [6:0]                i;                  // For loop byte index (512-bit DATAWIDTH max)

/* Knob Encoding
   [31:2]  Reserved
   [1]     back_pres  // 1: Backpressure H2C_tready. 0: Normal
   [0]     lossy      // 1: Lossy. 0: Lossless
*/
assign back_pres = knob[1];
assign lossy     = knob[0];

wire [5:0]  mty       = h2c_tuser_mty;                         // Empty Bytes in the last beat
wire [10:0] qid       = h2c_tuser_qid;                         // Queue ID
wire        chid      = 1'b0;                                  // Channel ID - Unused
wire        sop       = h2c_tvalid & h2c_tready & (~h2c_busy); // Start of Packet
wire        eop       = h2c_tvalid & h2c_tready & h2c_tlast;   // End of Packet
wire [5:0]  leb       = (DATA_WIDTH - h2c_tuser_mty - 1);      // Last Enabled Byte
wire [5:0]  meb       = 6'b0;                                  // First Enabled Byte - Unused
wire        zero_byte = h2c_tuser_zero_byte;                   // WriteBack sent to Host
wire [7:0]  pcie_err  = {7'b0, h2c_tuser_err};                 // PCIe Error occured - Upper bits deprecated
wire [2:0]  port_id   = h2c_tuser_port_id;                     // Port ID - Unused
wire [31:0] h2c_desc  = h2c_tuser_mdata;                       // H2C Descriptor[31:0]

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
assign crc           = metadata[HDR_WIDTH-1 -:8];
assign exp_qid       = header[1][2 +: QID_WIDTH];
assign btt           = header[0][0 +: LEN_WIDTH];
assign byte_idx      = header[0][LEN_WIDTH +: LEN_WIDTH];
assign header[0]     = metadata[31:0];
assign header[1]     = metadata[63:32];
assign ctrl          = metadata_raw[33:32];
assign metadata      = (ctrl == 2'b00) ? metadata_raw : (~metadata_raw); // Inversion will include CTRL. 
                                                                         // It's ok as it's not being used anymore
assign metadata_raw  = h2c_tdata[0+:HDR_WIDTH];

/* Error Detector - Must be sampled for one cycle at EOP only
   [31-:LEN_WIDTH)]   h2c_len            // Received Packet Length
   [(31-LEN_WIDTH):5] rsvd               // Unused
   [4]                pcie_err_ored      // PCIe Read Error
   [3]                crc_err            // CRC Error
   [2]                par_err            // Parity Error
   [1]                len_err            // Length Error
   [0]                qid_err            // QID Mismatch
*/
assign stat_err[31-:LEN_WIDTH]    = h2c_len;
assign stat_err[(31-LEN_WIDTH):6] = 'h0;
assign stat_err[5]                = dat_64B_err;
assign stat_err[4]                = pcie_err_ored;
assign stat_err[3]                = crc_err;
assign stat_err[2]                = par_err;
assign stat_err[1]                = len_err;
assign stat_err[0]                = qid_err;

// H2C Control / Check
// Reset when SOP is set. Once set, it's held until the next SOP.
// All of these error signals must be sampled for one cycle at EOP only
// CAUTION: If the last transfer beat is less than the HDR_WIDTH, then all checkers are disabled due to incomplete Metadata
//          except dat_64B_err and pcie_err_ored
assign bad_metadata = ((DATA_WIDTH - mty) < HDR_WIDTH) ? 1'b1 : 1'b0;

always @(posedge user_clk) begin
  if (~user_reset_n) begin
    dat_64B_err   <= #TCQ 1'b0;
    pcie_err_ored <= #TCQ 1'b0;
    crc_err       <= #TCQ 1'b0;
    par_err       <= #TCQ 1'b0;
    len_err       <= #TCQ 1'b0;
    qid_err       <= #TCQ 1'b0;
  end else begin
  
    if (h2c_tvalid & h2c_tready) begin // Only do checking if data is valid and ready
      
      // PCIe Err
      if (sop) begin
        pcie_err_ored <= #TCQ |pcie_err;
      end else if (h2c_busy) begin
        pcie_err_ored <= #TCQ pcie_err_ored | (|pcie_err);
      end
    
      // CRC Check
      if (sop) begin
        crc_err <= #TCQ bad_metadata ? 1'b0 : (crc != exp_crc);
      end else if (h2c_busy) begin
        crc_err <= #TCQ crc_err | (bad_metadata ? 1'b0 : (crc != exp_crc));
      end
    
      // Parity Check
      if (sop) begin
        par_err  <= #TCQ bad_metadata ? 1'b0 : (h2c_dpar != dpar);
      end else if (h2c_busy) begin
        par_err  <= #TCQ par_err | (bad_metadata ? 1'b0 : (h2c_dpar != dpar));
      end
    
      // Repeating Data Pattern Check
      if (sop) begin
        if (DATA_WIDTH == 512) begin
          dat_64B_err <= #TCQ ((h2c_tdata_nonmty[63:0] | h2c_tdata_nonmty[127:64] | h2c_tdata_nonmty[191:128] | h2c_tdata_nonmty[255:192] |
                                h2c_tdata_nonmty[319:256] | h2c_tdata_nonmty[383:320] | h2c_tdata_nonmty[447:384] | h2c_tdata_nonmty[511:448]) != h2c_tdata_nonmty[63:0]) ? 1'b1 : 1'b0;
        end else if (DATA_WIDTH == 256) begin
          dat_64B_err <= #TCQ ((h2c_tdata_nonmty[63:0] | h2c_tdata_nonmty[127:64] | h2c_tdata_nonmty[191:128] | h2c_tdata_nonmty[255:192]) != h2c_tdata_nonmty[63:0]) ? 1'b1 : 1'b0;
        end else if (DATA_WIDTH == 128) begin
          dat_64B_err <= #TCQ ((h2c_tdata_nonmty[63:0] | h2c_tdata_nonmty[127:64]) != h2c_tdata_nonmty[63:0]) ? 1'b1 : 1'b0;
        end else begin // 64-bit case never have repeating data pattern error
          dat_64B_err <= #TCQ 1'b0;
        end
      end else begin
        if (DATA_WIDTH == 512) begin
          dat_64B_err <= #TCQ dat_64B_err | (((h2c_tdata_nonmty[63:0]    | h2c_tdata_nonmty[127:64]  | h2c_tdata_nonmty[191:128] | h2c_tdata_nonmty[255:192] |
                                               h2c_tdata_nonmty[319:256] | h2c_tdata_nonmty[383:320] | h2c_tdata_nonmty[447:384] | h2c_tdata_nonmty[511:448]) != h2c_tdata_nonmty[63:0]) ? 1'b1 : 1'b0);
        end else if (DATA_WIDTH == 256) begin
          dat_64B_err <= #TCQ dat_64B_err | (((h2c_tdata_nonmty[63:0] | h2c_tdata_nonmty[127:64] | h2c_tdata_nonmty[191:128] | h2c_tdata_nonmty[255:192]) != h2c_tdata_nonmty[63:0]) ? 1'b1 : 1'b0);
        end else if (DATA_WIDTH == 128) begin
          dat_64B_err <= #TCQ dat_64B_err | (((h2c_tdata_nonmty[63:0] | h2c_tdata_nonmty[127:64]) != h2c_tdata_nonmty[63:0]) ? 1'b1 : 1'b0);
        end else begin // 64-bit case never have repeating data pattern error
          dat_64B_err <= #TCQ 1'b0;
        end
      end
    
      // Length Check
      // It checks every descriptor (BYTE_CREDIT) only. It does not cover a transfer spanning over 4K
      if (lossy) begin // Right now lossy case is checking the same thing until over 4K packet checker is added
        if (sop & eop) begin  // One beat transfer
          len_err  <= #TCQ bad_metadata ? 1'b0 : (btt != ((DATA_WIDTH/8) - mty));
        end else if (sop) begin
          len_err  <= #TCQ 1'b0;
        end else if (h2c_busy) begin
          len_err  <= #TCQ len_err | bad_metadata ? 1'b0 : (
                                                            eop ? (((DATA_WIDTH/8) - mty) != (btt - byte_idx)) : ((h2c_len % BYTE_CREDIT)  != (byte_idx % BYTE_CREDIT))
                                                           );
        end
      end else begin // Lossless
        if (sop & eop) begin  // One beat transfer
          len_err  <= #TCQ bad_metadata ? 1'b0 : (btt != ((DATA_WIDTH/8) - mty));
        end else if (sop) begin
          len_err  <= #TCQ 1'b0;
        end else if (h2c_busy) begin
          len_err  <= #TCQ len_err | bad_metadata ? 1'b0 : (
                                                            eop ? (((DATA_WIDTH/8) - mty) != (btt - byte_idx)) : ((h2c_len % BYTE_CREDIT)  != (byte_idx % BYTE_CREDIT))
                                                           );
        end
      end
    
      // QID Check
      if (sop) begin
        qid_err  <= #TCQ bad_metadata ? 1'b0 : (qid != exp_qid);
      end else if (h2c_busy) begin
        qid_err  <= #TCQ qid_err | (bad_metadata ? 1'b0 : (qid != exp_qid));
      end
      
    end // h2c_tvalid & h2c_tready
  end // ~user_reset_n
end // always

// h2c_busy
always @(posedge user_clk) begin
  if (~user_reset_n) begin
    h2c_busy   <= #TCQ 1'b0;
  end else begin
    if (sop & (~eop)) begin
      h2c_busy <= #TCQ 1'b1;
    end else if (eop & (~sop)) begin
      h2c_busy <= #TCQ 1'b0;
    end
    
    h2c_busy_reg <= #TCQ h2c_busy;
  end
end

// h2c_tready backpressure
always @(posedge user_clk) begin
  if (~user_reset_n) begin
    h2c_tready <= #TCQ 1'b0;
  end else begin
    h2c_tready <= #TCQ (back_pres & rand_num[8]) ? 1'b0: 1'b1;
  end
end

// Bytes Received
// Reset when SOP is set. Once set, it's held until the next SOP.
always @(posedge user_clk) begin
  if (~user_reset_n) begin
    h2c_len <= #TCQ {LEN_WIDTH{1'b0}};
  end else begin
    if (sop & eop) begin
      h2c_len <= #TCQ (DATA_WIDTH/8) - mty;
    end else if (sop) begin
      h2c_len <= #TCQ (DATA_WIDTH/8);
    end else if (h2c_busy & h2c_tvalid & h2c_tready) begin
      if (h2c_tlast) begin
        h2c_len <= #TCQ h2c_len + ((DATA_WIDTH/8) - mty);
      end else begin
        h2c_len <= #TCQ h2c_len + (DATA_WIDTH/8);
      end
    end
  end
end

// Convert h2c_tdata with mty to a non-mty h2c_tdata
always @(posedge user_clk) begin
  for (i=0 ; i < (DATA_WIDTH/8); i = i + 1) begin : h2c_tdata_mty_byte
    h2c_tdata_nonmty[(i*8) +: 8] <= #TCQ (i < (DATA_WIDTH - mty)) ? h2c_tdata[(i*8) +:8] : h2c_tdata[0 +:8];
  end
end

// Parity / CRC Calculator
generate
  begin
    genvar pa;
    for (pa=0; pa < (DATA_WIDTH/8); pa = pa + 1) // Parity needs to be computed for every byte of data
    begin : parity_assign
      assign dpar[pa] = !( ^ h2c_tdata [8*(pa+1)-1:8*pa] );
    end
  end
endgenerate

generate
genvar crc_i;
for (crc_i = 0; crc_i < 8; crc_i = crc_i+1) begin
  assign exp_crc[crc_i] = metadata[(crc_i*7)+6] ^ metadata[(crc_i*7)+5] ^ metadata[(crc_i*7)+4] ^ metadata[(crc_i*7)+3] ^ metadata[(crc_i*7)+2] ^ metadata[(crc_i*7)+1] ^ metadata[(crc_i*7)+0];
end
endgenerate

endmodule
