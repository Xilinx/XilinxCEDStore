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
// File       : ST_c2h_cmpt.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

module ST_c2h_cmpt # (
  parameter DATA_WIDTH  = 512,             // 512 bit only
  parameter LEN_WIDTH   = 16,              // Must be 16. 16-bit is the maximum length the interface can handle.
  parameter QID_WIDTH   = 11,              // Must be 11. Queue ID bit width
  parameter TCQ         = 1
) (
  // Global
  input                           user_clk,
  input                           user_reset_n,
  
  // Control Signals
  input  [31:0]                   knob,  
  
  input                           c2h_formed,           // C2H packet is formed. Generates the Writeback for this packet
  input  [LEN_WIDTH-1:0]          btt_wb,               // C2H packet length in bytes of C2H packet attached to this Writeback (not Writeback length)
  input  [31:0]                   cmpt_size,
  input  [QID_WIDTH-1:0]          qid_wb,               // QID to use in the current transfer
  input                           marker_wb,            // C2H packet for this CMPT is a marker packet
  input                           c2h_fifo_is_full,     // C2H Bus FIFO is full
  output                          wb_is_full,           // CMPT Bus FIFO is full
  output                          cmpt_sent,            // CMPT packet is formed.
  
  // Custom Writeback
  input  [255:0]                  wb_dat,
  
  // Writeback Signals
  output [DATA_WIDTH-1:0]         s_axis_c2h_cmpt_tdata,
  output [1:0]                    s_axis_c2h_cmpt_size,
  output [(DATA_WIDTH/32)-1:0]    s_axis_c2h_cmpt_dpar,
  output                          s_axis_c2h_cmpt_tvalid,
  output                          s_axis_c2h_cmpt_tlast,
  input                           s_axis_c2h_cmpt_tready,
  
  // Writeback Control Ports
  output [10:0]                   s_axis_c2h_cmpt_ctrl_qid,
  output [1:0]                    s_axis_c2h_cmpt_ctrl_cmpt_type,
  output [15:0]                   s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id,
  output [2:0]                    s_axis_c2h_cmpt_ctrl_port_id,
  output                          s_axis_c2h_cmpt_ctrl_marker,
  output                          s_axis_c2h_cmpt_ctrl_user_trig,
  output [2:0]                    s_axis_c2h_cmpt_ctrl_col_idx,
  output [2:0]                    s_axis_c2h_cmpt_ctrl_err_idx
);

  localparam       FIFO_TUSER_WIDTH_PART = 1  + QID_WIDTH + 2;         // Marker + Qid + CMPT Size 2bits
  localparam       FIFO_TUSER_WIDTH      = 16 + FIFO_TUSER_WIDTH_PART; // Add Packet Counter

  wire [(DATA_WIDTH/32)-1:0]  cmpt_dpar;           // CMPT Parity
  
  // QDMA CMPT Bus FIFO
  reg  [DATA_WIDTH-1:0]       cmpt_tdata_fifo_in;
  reg                         cmpt_tlast_fifo_in;
  reg                         cmpt_tvalid_fifo_in;  // Do not wait for cmpt_tready_fifo_in before asserting cmpt_tvalid_fifo_in
  wire                        cmpt_tready_fifo_in;
  reg  [FIFO_TUSER_WIDTH_PART-1:0] cmpt_tuser_fifo_in_part; // Partial information of the cmpt_tuser_fifo_in
  wire [FIFO_TUSER_WIDTH-1:0] cmpt_tuser_fifo_in;      // Full information of the cmpt_tuser_fifo_in. It appends the pld_pkt_id
  wire [DATA_WIDTH-1:0]       cmpt_tdata_fifo_out;
  wire                        cmpt_tlast_fifo_out;
  wire                        cmpt_tvalid_fifo_out; // Back-pressure the C2H data until we have enough data to do long burst or is forced to send one
  wire                        cmpt_tready_fifo_out; // Back-pressure the C2H data until we have enough data to do long burst or is forced to send one
  wire [FIFO_TUSER_WIDTH-1:0] cmpt_tuser_fifo_out;
  wire                        prog_full_axis;       // CMPT Bus FIFO is almost full - can only accept one more descriptor worth of data
  wire                        almost_empty_axis;    // CMPT Bus FIFO is empty
  
  reg  [11:0]                 idle_fifo_cntr;       // Keep track of how many clock cycles CMPT Bus FIFO has been idling
  wire                        fifo_idle_timeout;    // CMPT Bus FIFO has been idling for too long
  wire                        cmpt_fifo_start;      // Start dumping CMPT Bus FIFO
  reg                         cmpt_fifo_active;     // Set when CMPT Bus FIFO begins transfer and clears only when it's empty
  
  logic wb_sm;
  localparam
             SM_IDL = 1'b0,
             SM_S1  = 1'b1;

  // Completion size information
  // cmpt_size[1:0] = 00 : 8Bytes of data 1 beat.
  // cmpt_size[1:0] = 01 : 16Bytes of data 1 beat.
  // cmpt_size[1:0] = 10 : 32Bytes of data 2 beat.
  
  // write back data format
  // Standart format
  // 0 : data format. 0 = standard format, 1 = user defined.
  // [11:1] : QID
  // [19:12] : // reserved
  // [255:20] : User data.
  // this format should be same for two cycle if type is [1] is set.
  
  // This is keeping track of the C2H Packet ID. CMPT being sent needs to use this Packet ID too
  reg [15:0] c2h_pkt_counter = 16'd1; // First Packet ID will always start at 1
  always @(posedge user_clk) begin
    if (~user_reset_n) begin
      c2h_pkt_counter <= 16'd1;       // First Packet ID will always start at 1
    end else begin
      if (cmpt_tvalid_fifo_in & cmpt_tready_fifo_in & cmpt_tlast_fifo_in) begin
        c2h_pkt_counter <= c2h_pkt_counter + 1;
      end
    end
  end
  
  always @(posedge user_clk) begin
    if (~user_reset_n) begin
      wb_sm                    <= SM_IDL;
      cmpt_tvalid_fifo_in      <= 1'b0;
      cmpt_tlast_fifo_in       <= 1'b0;
      cmpt_tuser_fifo_in_part  <= 14'b0;
    end
    else begin
      
    cmpt_tuser_fifo_in_part    <= {marker_wb, qid_wb[10:0], cmpt_size[1:0]};
      
      case (wb_sm)
        SM_IDL :
        begin
//          if (s_axis_c2h_tlast & s_axis_c2h_tready) begin // Must not wait for TLAST as it will cause payload fifo to fill up
          if (c2h_formed) begin
            wb_sm               <= SM_S1;
            cmpt_tdata_fifo_in  <= {{3{wb_dat[127:0]}}, wb_dat[127:20], btt_wb[15:0], 1'b1, 3'b000}; // Example driver expects 2018.2 Completion Entry format. We do this in "user-defined" data to mimic that Entry.
                                                                                                     // bit[2:0] is reserved. bit[3] = "desc_used". bit[19:4] = C2H packet length
            cmpt_tvalid_fifo_in <= 1'b1;
            cmpt_tlast_fifo_in  <= 1'b1;
          end
        end
          
        SM_S1 :
        begin
          if (cmpt_tready_fifo_in) begin
            
            if (c2h_formed) begin
              wb_sm               <= SM_S1;
              cmpt_tdata_fifo_in  <= {{3{wb_dat[127:0]}}, wb_dat[127:20], btt_wb[15:0], 1'b1, 3'b000}; // Example driver expects 2018.2 Completion Entry format. We do this in "user-defined" data to mimic that Entry.
                                                                                                       // bit[2:0] is reserved. bit[3] = "desc_used". bit[19:4] = C2H packet length
              cmpt_tvalid_fifo_in <= 1'b1;
              cmpt_tlast_fifo_in  <= 1'b1;
              
            end else begin
            
              wb_sm               <= SM_IDL;
              cmpt_tdata_fifo_in  <= {{3{wb_dat[127:0]}}, wb_dat[127:20], btt_wb[15:0], 1'b1, 3'b000}; // Example driver expects 2018.2 Completion Entry format. We do this in "user-defined" data to mimic that Entry.
                                                                                                       // bit[2:0] is reserved. bit[3] = "desc_used". bit[19:4] = C2H packet length.
              cmpt_tvalid_fifo_in <= 1'b0;
              cmpt_tlast_fifo_in  <= 1'b0;
            
            end // c2h_formed
            
          end // cmpt_tready_fifo_in
        end // SM_S1
            
        default : begin
          wb_sm               <= SM_IDL;
          cmpt_tvalid_fifo_in <= 1'b0;
          cmpt_tlast_fifo_in  <= 1'b0;
        end
      endcase // case (wb_sm)
    end
  end
   
  // Parity Generator
  generate
    begin
      genvar pa;
      for (pa=0; pa < (DATA_WIDTH/32); pa = pa + 1) // Parity needs to be computed for every DW of data
      begin : parity_assign
        assign cmpt_dpar[pa] = !( ^ s_axis_c2h_cmpt_tdata [32*(pa+1)-1:32*pa] );
      end
    end
  endgenerate
   
  assign s_axis_c2h_cmpt_dpar = cmpt_dpar;

  assign cmpt_sent = c2h_formed & ((wb_sm == SM_IDL) | ((wb_sm == SM_S1) & cmpt_tready_fifo_in)) ? 1'b1 : 1'b0;
  
  // AXI Stream FIFO
  // Buffer the packet until the FIFO has a lot
  xpm_fifo_axis #(
    .CDC_SYNC_STAGES(2),            // DECIMAL
    .CLOCKING_MODE("common_clock"), // String
    .ECC_MODE("no_ecc"),            // String
    .FIFO_DEPTH(2048),              // DECIMAL
    .FIFO_MEMORY_TYPE("auto"),      // String
    .PACKET_FIFO("false"),          // String
    .PROG_EMPTY_THRESH(512),        // DECIMAL -- Not used
    .PROG_FULL_THRESH(2048-8),      // DECIMAL -- When asserted, FIFO only have spot for 8 descriptor left. WARNING: XPM FIFO has a limit of 5, do not set for less than 5
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
  
    .m_axis_tdata(cmpt_tdata_fifo_out),      // TDATA_WIDTH-bit output: TDATA: The primary payload that is
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
  
    .m_axis_tlast(cmpt_tlast_fifo_out),      // 1-bit output: TLAST: Indicates the boundary of a packet.
    .m_axis_tstrb(),                         // TDATA_WIDTH-bit output: TSTRB: The byte qualifier that
                                             // indicates whether the content of the associated byte of TDATA
                                             // is processed as a data byte or a position byte. For a 64-bit
                                             // DATA, bit 0 corresponds to the least significant byte on
                                             // DATA, and bit 0 corresponds to the least significant byte on
                                             // DATA, and bit 7 corresponds to the most significant byte. For
                                             // example: STROBE[0] = 1b, DATA[7:0] is valid STROBE[7] = 0b,
                                             // DATA[63:56] is not valid .
  
    .m_axis_tuser(cmpt_tuser_fifo_out),      // TUSER_WIDTH-bit output: TUSER: The user-defined sideband
                                             // information that can be transmitted alongside the data
                                             // stream.
  
    .m_axis_tvalid(cmpt_tvalid_fifo_out),    // 1-bit output: TVALID: Indicates that the master is driving a
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
  
    .s_axis_tready(cmpt_tready_fifo_in),     // 1-bit output: TREADY: Indicates that the slave can accept a
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
  
    .m_axis_tready(cmpt_tready_fifo_out),    // 1-bit input: TREADY: Indicates that the slave can accept a
                                             // transfer in the current cycle.
  
    .s_aclk(user_clk),                       // 1-bit input: Slave Interface Clock: All signals on slave
                                             // interface are sampled on the rising edge of this clock.
  
    .s_aresetn(user_reset_n),                // 1-bit input: Active low asynchronous reset.
    .s_axis_tdata(cmpt_tdata_fifo_in),       // TDATA_WIDTH-bit input: TDATA: The primary payload that is
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
  
    .s_axis_tlast(cmpt_tlast_fifo_in),       // 1-bit input: TLAST: Indicates the boundary of a packet.
    .s_axis_tstrb({(DATA_WIDTH/8){1'b1}}),   // TDATA_WIDTH-bit input: TSTRB: The byte qualifier that
                                             // indicates whether the content of the associated byte of TDATA
                                             // is processed as a data byte or a position byte. For a 64-bit
                                             // DATA, bit 0 corresponds to the least significant byte on
                                             // DATA, and bit 0 corresponds to the least significant byte on
                                             // DATA, and bit 7 corresponds to the most significant byte. For
                                             // example: STROBE[0] = 1b, DATA[7:0] is valid STROBE[7] = 0b,
                                             // DATA[63:56] is not valid .
  
    .s_axis_tuser(cmpt_tuser_fifo_in),       // TUSER_WIDTH-bit input: TUSER: The user-defined sideband
                                             // information that can be transmitted alongside the data
                                             // stream.
  
    .s_axis_tvalid(cmpt_tvalid_fifo_in)      // 1-bit input: TVALID: Indicates that the master is driving a
                                             // valid transfer. A transfer takes place when both TVALID and
                                             // TREADY are asserted .
  
  );
  
  // Idle timeout counter - Wait for 4096 clock cycles
  // If no more writeback is queued, send the stale writeback in the FIFO over the link
  always @(posedge user_clk) begin
    if (~user_reset_n) begin
      idle_fifo_cntr <= #TCQ 12'b0;
    end else begin
      if (cmpt_tready_fifo_in & cmpt_tvalid_fifo_in) begin
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
      cmpt_fifo_active   <= #TCQ 1'b0;
    end else begin
      if (almost_empty_axis) begin
        cmpt_fifo_active <= #TCQ 1'b0;
      end else if (s_axis_c2h_cmpt_tvalid) begin
        cmpt_fifo_active <= #TCQ 1'b1;
      end else begin
        cmpt_fifo_active <= #TCQ cmpt_fifo_active;
      end
    end
  end
  
  assign cmpt_fifo_start        = (((~almost_empty_axis) & (fifo_idle_timeout | c2h_fifo_is_full | prog_full_axis)) | knob[0]) ? 1'b1 : 1'b0;
  assign s_axis_c2h_cmpt_tvalid = ( (cmpt_fifo_start | cmpt_fifo_active) && (!knob[1]) ) ? cmpt_tvalid_fifo_out   : 1'b0;
  assign cmpt_tready_fifo_out   = ( (cmpt_fifo_start | cmpt_fifo_active) && (!knob[1]) ) ? s_axis_c2h_cmpt_tready : 1'b0;
  
  assign wb_is_full             = prog_full_axis;
  
  assign cmpt_tuser_fifo_in     = {c2h_pkt_counter, cmpt_tuser_fifo_in_part};
  
  assign s_axis_c2h_cmpt_tdata  = cmpt_tdata_fifo_out;
  assign s_axis_c2h_cmpt_tlast  = cmpt_tlast_fifo_out;
  assign s_axis_c2h_cmpt_size   = cmpt_tuser_fifo_out[1:0];
  
  // C2H Completion Control Ports
  assign s_axis_c2h_cmpt_ctrl_qid             = cmpt_tuser_fifo_out[12:2];  // QID for Completion Packet
  assign s_axis_c2h_cmpt_ctrl_cmpt_type       = 2'b11;                      // 0 = No PLD/Wait, 1 = No PLD but Wait, 2 = Reserved, 3 = Has PLD
  assign s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id = cmpt_tuser_fifo_out[29:14];
  assign s_axis_c2h_cmpt_ctrl_port_id         = 3'b0;
  assign s_axis_c2h_cmpt_ctrl_marker          = cmpt_tuser_fifo_out[13];
  assign s_axis_c2h_cmpt_ctrl_user_trig       = 1'b0;
  assign s_axis_c2h_cmpt_ctrl_col_idx         = 3'b0;                       // User Defined Color Bit - Not used
  assign s_axis_c2h_cmpt_ctrl_err_idx         = 3'b0;                       // User Defined Error Bit - Not used

endmodule
