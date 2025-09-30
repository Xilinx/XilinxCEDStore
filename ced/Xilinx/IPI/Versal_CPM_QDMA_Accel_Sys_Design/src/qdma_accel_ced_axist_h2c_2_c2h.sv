//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//-----------------------------------------------------------------------------
//
// Project    : CPM5-QDMA based Acceleration system design 
// File       : qdma_accel_ced_axist_h2c_2_c2h.sv
// Version    : 1.0
//This module instantiates AXI-ST FIFO to store H2C-ST data. C2H-ST interface is driven using this FIFO output
`timescale 1ps / 1ps
module qdma_accel_ced_axist_h2c_2_c2h #(
  parameter BYTE_CREDIT = 4096,                 // Must be power of 2. Example design driver always issues 4KB descriptor, so we're limiting it to 4KB per credit.
  parameter DATA_WIDTH  = 512,                   // 64, 128, 256, or 512 bit only
  parameter QID_WIDTH   = 12,                   // Must be 12. Queue ID bit width 
  parameter TUSER_WIDTH  = 38,                   // Must be 16. 16-bit is the maximum length the interface can handle.  
  parameter TCQ         = 1
) (
  // Global
  input                       user_clk,
  input                       user_reset_n,
  
  // Control Signals
  input  [31:0]               knob,             // [0] = Start transfer immediately. [1] = Stop transfer immediately. [2] = Enable DROP test. [3] = Random BTT. [4] = Send Marker
                                                // [31:21] = Number of QID to use in DROP case.
  
  output					h2c_tready,
  input						h2c_tvalid,
  input						h2c_err,
  input						h2c_tlast,
  input	[TUSER_WIDTH-1:0]	h2c_tuser,
  input [DATA_WIDTH-1:0]    h2c_tdata,
  
  input                       wb_is_full,       // CMPT Bus FIFO is full
  
  // QDMA C2H Bus
  output [DATA_WIDTH-1:0]     c2h_tdata,
  output                      c2h_tlast,
  output                      c2h_tvalid,  // Do not wait for c2h_tready before asserting c2h_tvalid
  input                       c2h_tready,
  output	[TUSER_WIDTH-1:0] c2h_tuser,
  
  output                      c2h_formed,       // First Beat of C2H    
  output                      c2h_fifo_is_full // C2H Bus FIFO is full  
);


(* MARK_DEBUG="true" *) reg                         c2h_fifo_active;     // Set when C2H Bus FIFO begins transfer and clears only when it's empty
(* MARK_DEBUG="true" *) wire                        almost_empty_axis;   // C2H Bus FIFO is empty
(* MARK_DEBUG="true" *) wire                        c2h_fifo_start;      // Start dumping C2H Bus FIFO
(* MARK_DEBUG="true" *) wire                        prog_full_axis;      // C2H Bus FIFO is almost full - can only accept one more descriptor worth of data
(* MARK_DEBUG="true" *) wire                        c2h_tvalid_fifo_out; // Back-pressure the C2H data until we have enough data to do long burst or is forced to send one
(* MARK_DEBUG="true" *) wire                        c2h_tready_fifo_out; // Back-pressure the C2H data until we have enough data to do long burst or is forced to send one
 (* MARK_DEBUG="true" *) logic [TUSER_WIDTH-1:0] c2h_tuser_fifo_out;
 (* MARK_DEBUG="true" *) logic [TUSER_WIDTH-1:0] h2c_tuser_fifo_in;


//assign h2c_tuser_fifo_in = {{(TUSER_WIDTH-15){1'b0}},h2c_pkt_id,h2c_sop,h2c_tuser_mty};
assign h2c_tuser_fifo_in = h2c_tuser;
assign c2h_tuser = c2h_tuser_fifo_out;
// AXI Stream FIFO
// Buffer the packet until the FIFO has a lot
xpm_fifo_axis #(
  .CDC_SYNC_STAGES(2),            // DECIMAL
  .CLOCKING_MODE("common_clock"), // String
  .ECC_MODE("no_ecc"),            // String
  .FIFO_DEPTH(1024),              // DECIMAL -- 64KB FIFO = 1024 * 64Bytes/cycle (DATA_WIDTH)
  .FIFO_MEMORY_TYPE("auto"),      // String
  .PACKET_FIFO("false"),          // String
  .PROG_EMPTY_THRESH(512),       // DECIMAL -- Not used
  .PROG_FULL_THRESH(1024-(BYTE_CREDIT/DATA_WIDTH)-1), // DECIMAL -- When asserted, FIFO only have spot for one descriptor left.
  .RD_DATA_COUNT_WIDTH(11),       // DECIMAL
  .RELATED_CLOCKS(0),             // DECIMAL
  .TDATA_WIDTH(DATA_WIDTH),       // DECIMAL
  .TDEST_WIDTH(1),                // DECIMAL
  .TID_WIDTH(1),                  // DECIMAL
  .TUSER_WIDTH(TUSER_WIDTH), // DECIMAL
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

  .s_axis_tready(h2c_tready),      // 1-bit output: TREADY: Indicates that the slave can accept a
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
  .s_axis_tdata(h2c_tdata),        // TDATA_WIDTH-bit input: TDATA: The primary payload that is
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

  .s_axis_tlast(h2c_tlast),        // 1-bit input: TLAST: Indicates the boundary of a packet.
  .s_axis_tstrb({(DATA_WIDTH/8){1'b1}}),   // TDATA_WIDTH-bit input: TSTRB: The byte qualifier that
                                           // indicates whether the content of the associated byte of TDATA
                                           // is processed as a data byte or a position byte. For a 64-bit
                                           // DATA, bit 0 corresponds to the least significant byte on
                                           // DATA, and bit 0 corresponds to the least significant byte on
                                           // DATA, and bit 7 corresponds to the most significant byte. For
                                           // example: STROBE[0] = 1b, DATA[7:0] is valid STROBE[7] = 0b,
                                           // DATA[63:56] is not valid .

  .s_axis_tuser(h2c_tuser_fifo_in),        // TUSER_WIDTH-bit input: TUSER: The user-defined sideband
                                           // information that can be transmitted alongside the data
                                           // stream.

  .s_axis_tvalid(h2c_tvalid)       // 1-bit input: TVALID: Indicates that the master is driving a
                                           // valid transfer. A transfer takes place when both TVALID and
                                           // TREADY are asserted .

);



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

assign c2h_fifo_start      = ((~almost_empty_axis) |  wb_is_full | prog_full_axis | knob[0]) ? 1'b1 : 1'b0;
//assign c2h_tvalid          = ( (c2h_fifo_start | c2h_fifo_active | !c2h_pkt_drop) && (!knob[1]) ) ? c2h_tvalid_fifo_out : 1'b0;
assign c2h_tvalid          = ( (c2h_fifo_start | c2h_fifo_active ) && (!knob[1]) ) ? c2h_tvalid_fifo_out : 1'b0;
assign c2h_tready_fifo_out = ( (c2h_fifo_start | c2h_fifo_active) && (!knob[1]) ) ? c2h_tready          : 1'b0;

assign c2h_fifo_is_full    = prog_full_axis;
//assign c2h_pkt_id		   = c2h_tuser_fifo_out [14:7];
assign c2h_formed = (c2h_tready & c2h_tvalid & c2h_tlast) ? 1'b1 : 1'b0;

endmodule