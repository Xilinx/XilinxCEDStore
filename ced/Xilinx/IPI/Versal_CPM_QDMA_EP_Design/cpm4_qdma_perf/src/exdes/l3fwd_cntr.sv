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
// File       : l3fwd_cntr.sv
// Version    : 5.0
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps

module l3fwd_cntr #(
  parameter C_CNTR_WIDTH      = 64,  // Counter bit width; can be set upto 64-bit only. Running on user_clk frequency.
                                     // We recommend keeping it large enough to not rolling over for a few seconds
  parameter C_DATA_WIDTH      = 256, // 64, 128, 256, or 512 bit only
  parameter QID_WIDTH         = 11,  // Must be 11. Queue ID bit width
  parameter TCQ               = 1
)
(

  // Global
  input                          user_clk,
  
  // Control Signals
  input  [C_CNTR_WIDTH-1:0]      user_l3fwd_max,  // Set the size of measurement window (clock cycle). max/min/sum/latency reset, on every <user_cntr_max> clock cycles.
  input                          user_l3fwd_en,   // 1 = Replace c2h_tdata data pattern with a timestamp. 0 = regular test data pattern
  input                          user_l3fwd_mode, // 1 = Single measurement where only one packet is sent and received. 0 = Continuous measurement on each packet sent and received
  input                          user_l3fwd_rst,  // 1 = Reset all counters. 0 = Running
  input                          user_l3fwd_read, // 1 = Measurement value is read. 0 = _o output registers will only be updated once until user_cntr_read is pulsed again.
  
  // C2H Input Signals from ST_C2H Module
  input  [C_DATA_WIDTH-1 :0]     s_axis_c2h_tdata_i,
  input  [C_DATA_WIDTH/8-1 :0]   s_axis_c2h_dpar_i,
  input                          s_axis_c2h_ctrl_marker_i,
  input  [15:0]                  s_axis_c2h_ctrl_len_i,
  input  [QID_WIDTH-1:0]         s_axis_c2h_ctrl_qid_i,
  input                          s_axis_c2h_ctrl_user_trig_i,
  input                          s_axis_c2h_ctrl_dis_cmpt_i,
  input                          s_axis_c2h_ctrl_imm_data_i,
  input                          s_axis_c2h_tvalid_i,
  output                         s_axis_c2h_tready_i,
  input                          s_axis_c2h_tlast_i,
  input  [5:0]                   s_axis_c2h_mty_i,
  
  // C2H Output Signals to QDMA IP
  output [C_DATA_WIDTH-1 :0]     s_axis_c2h_tdata_o,
  output [C_DATA_WIDTH/8-1 :0]   s_axis_c2h_dpar_o,
  output                         s_axis_c2h_ctrl_marker_o,
  output [15:0]                  s_axis_c2h_ctrl_len_o,
  output [QID_WIDTH-1:0]         s_axis_c2h_ctrl_qid_o,
  output                         s_axis_c2h_ctrl_user_trig_o,
  output                         s_axis_c2h_ctrl_dis_cmpt_o,
  output                         s_axis_c2h_ctrl_imm_data_o,
  output                         s_axis_c2h_tvalid_o,
  input                          s_axis_c2h_tready_o,
  output                         s_axis_c2h_tlast_o,
  output [5:0]                   s_axis_c2h_mty_o,
  
  // H2C Input Signals to the ST_H2C Module
  input  [C_DATA_WIDTH-1 :0]     m_axis_h2c_tdata_i,
  input  [C_DATA_WIDTH/8-1 :0]   m_axis_h2c_dpar_i,
  input                          m_axis_h2c_tvalid_i,
  output                         m_axis_h2c_tready_i,
  input                          m_axis_h2c_tlast_i,
  input  [10:0]                  m_axis_h2c_tuser_qid_i,
  input  [2:0]                   m_axis_h2c_tuser_port_id_i,
  input                          m_axis_h2c_tuser_err_i,
  input  [31:0]                  m_axis_h2c_tuser_mdata_i,
  input  [5:0]                   m_axis_h2c_tuser_mty_i,
  input                          m_axis_h2c_tuser_zero_byte_i,
  
  // H2C Output Signals from QDMA IP
  output [C_DATA_WIDTH-1 :0]     m_axis_h2c_tdata_o,
  output [C_DATA_WIDTH/8-1 :0]   m_axis_h2c_dpar_o,
  output                         m_axis_h2c_tvalid_o,
  input                          m_axis_h2c_tready_o,
  output                         m_axis_h2c_tlast_o,
  output [10:0]                  m_axis_h2c_tuser_qid_o,
  output [2:0]                   m_axis_h2c_tuser_port_id_o,
  output                         m_axis_h2c_tuser_err_o,
  output [31:0]                  m_axis_h2c_tuser_mdata_o,
  output [5:0]                   m_axis_h2c_tuser_mty_o,
  output                         m_axis_h2c_tuser_zero_byte_o,
  
  // Measurement Signals
  output reg [C_CNTR_WIDTH-1:0]  max_latency_o,    // Copy of max_latency when trigger is set.
  output reg [C_CNTR_WIDTH-1:0]  min_latency_o,    // Copy of min_latency when trigger is set.
  output reg [C_CNTR_WIDTH-1:0]  sum_latency_o,    // Copy of sum_latency when trigger is set.
  output reg [C_CNTR_WIDTH-1:0]  num_pkt_rcvd_o    // Copy of num_pkt_rcvd when trigger is set.

);

reg [C_CNTR_WIDTH-1:0]    cap_cnts;      // Capture counter for each measurement window
reg [C_CNTR_WIDTH-1:0]    latency_cnts;  // Latency calculation
reg [C_CNTR_WIDTH-1:0]    max_latency;   // Maximum latency for each measurement window
reg [C_CNTR_WIDTH-1:0]    min_latency;   // Minimum latency for each measurement window
reg [C_CNTR_WIDTH-1:0]    sum_latency;   // All latency number added together for each measurement window
reg [C_CNTR_WIDTH-1:0]    num_pkt_rcvd;  // Number of packet received. sum_latency / num_pkt_rcvd = avg_latency

reg                       pkt_in_flight; // One packet is sent out in C2H direction. Clears when one H2C packet is received.
                                         // Only used when user_l3fwd_mode == 1

reg [C_CNTR_WIDTH-1:0]    free_cnts = 0;   // Free running counter

wire [C_DATA_WIDTH-1:0]     c2h_tdata;     // Timestamp
wire [(C_DATA_WIDTH/8)-1:0] dpar;          // Parity

wire                      trigger;    // Counters' trigger point
reg                       cntr_read;  // Counters were read so we can store a new value in the output registers
reg                       pkt_rcvd;   // H2C Packet is received

// Parity Generator
generate
  begin
    genvar pa;
    for (pa=0; pa < (C_DATA_WIDTH/8); pa = pa + 1) // Parity needs to be computed for every byte of data
    begin : parity_assign
      assign dpar[pa] = !( ^ c2h_tdata [8*(pa+1)-1:8*pa] );
    end
  end
endgenerate

always @(posedge user_clk) begin
  free_cnts   <= #TCQ free_cnts + 1;
end

assign trigger = (cap_cnts == user_l3fwd_max) ? 1'b1 : 1'b0;

// Measure latency when we receive a packet on H2C.
always @(posedge user_clk) begin
  if (user_l3fwd_rst) begin
    latency_cnts  <= #TCQ 'h0;
    pkt_in_flight <= #TCQ 1'b0;
    pkt_rcvd     <= #TCQ 1'b0;
  end else begin
    // If the value is negative, do two complement of it.
    latency_cnts  <= #TCQ ( m_axis_h2c_tvalid_i & m_axis_h2c_tready_i & m_axis_h2c_tlast_i )
                                                ? ( (m_axis_h2c_tdata_i[C_CNTR_WIDTH-1:0] <= free_cnts) ? (free_cnts - m_axis_h2c_tdata_i[C_CNTR_WIDTH-1:0])
                                                                                                     : ((~(free_cnts - m_axis_h2c_tdata_i[C_CNTR_WIDTH-1:0])) + 1)
                                                ) : latency_cnts;
                                                
    pkt_rcvd      <= #TCQ ( m_axis_h2c_tvalid_i & m_axis_h2c_tready_i & m_axis_h2c_tlast_i ) ? 1'b1 : 1'b0;
    
    // There will never be a packet on H2C on the same clock cycle that C2H is sent and vice versa in user_l3fwd_mode == 1
    pkt_in_flight <= #TCQ (s_axis_c2h_tvalid_i & s_axis_c2h_tready_i & s_axis_c2h_tlast_i) ? 1'b1 : ( (m_axis_h2c_tvalid_i & m_axis_h2c_tready_i & m_axis_h2c_tlast_i) ? 1'b0 : pkt_in_flight);
  end
end

// Measurement window
always @(posedge user_clk) begin
  if (user_l3fwd_rst) begin
  
    cap_cnts     <= #TCQ 'h0;
    max_latency  <= #TCQ 'h0;
    min_latency  <= #TCQ {C_CNTR_WIDTH{1'b1}};
    sum_latency  <= #TCQ 'h0;
    num_pkt_rcvd <= #TCQ 'h0;
  
    cntr_read    <= #TCQ 1'b1;
    
  end else begin
  
    if (trigger) begin
      cap_cnts      <= #TCQ 'h0;
      cntr_read     <= #TCQ 1'b0;
      
      max_latency   <= #TCQ 'h0;
      min_latency   <= #TCQ {C_CNTR_WIDTH{1'b1}};
      sum_latency   <= #TCQ 'h0;
      num_pkt_rcvd  <= #TCQ 'h0;
    end else begin
      cap_cnts      <= #TCQ cap_cnts + 1;
      cntr_read     <= #TCQ user_l3fwd_read ? 1'b1 : cntr_read;
    
      max_latency   <= #TCQ ( pkt_rcvd & (latency_cnts > max_latency)) ? latency_cnts : max_latency;
      min_latency   <= #TCQ ( pkt_rcvd & (latency_cnts < min_latency)) ? latency_cnts : min_latency;
      sum_latency   <= #TCQ ( pkt_rcvd )                               ? (sum_latency + latency_cnts) : sum_latency;
    
      num_pkt_rcvd  <= #TCQ ( pkt_rcvd )                               ? (num_pkt_rcvd + 1) : num_pkt_rcvd;
    end
  end
end

// Sample counter values for reading
always @(posedge user_clk) begin
  if (user_l3fwd_rst) begin
    max_latency_o  <= #TCQ 'h0;
    min_latency_o  <= #TCQ {C_CNTR_WIDTH{1'b1}};
    sum_latency_o  <= #TCQ 'h0;
    num_pkt_rcvd_o <= #TCQ 'h0;
  end else begin
    max_latency_o  <= #TCQ (cntr_read & trigger) ? max_latency : max_latency_o;
    min_latency_o  <= #TCQ (cntr_read & trigger) ? min_latency : min_latency_o;
    sum_latency_o  <= #TCQ (cntr_read & trigger) ? sum_latency : sum_latency_o;
    num_pkt_rcvd_o <= #TCQ (cntr_read & trigger) ? num_pkt_rcvd : num_pkt_rcvd_o;
  end
end

// C2H
assign c2h_tdata                    = {(C_DATA_WIDTH/64){64'h0 | free_cnts}};
assign s_axis_c2h_tdata_o           = user_l3fwd_en ? c2h_tdata : s_axis_c2h_tdata_i;
// Everything else is a passthrough
assign s_axis_c2h_dpar_o            = user_l3fwd_en ? dpar : s_axis_c2h_dpar_i;
assign s_axis_c2h_ctrl_marker_o     = s_axis_c2h_ctrl_marker_i;
assign s_axis_c2h_ctrl_len_o        = s_axis_c2h_ctrl_len_i;
assign s_axis_c2h_ctrl_qid_o        = s_axis_c2h_ctrl_qid_i;
assign s_axis_c2h_ctrl_user_trig_o  = s_axis_c2h_ctrl_user_trig_i;
assign s_axis_c2h_ctrl_dis_cmpt_o   = s_axis_c2h_ctrl_dis_cmpt_i;
assign s_axis_c2h_ctrl_imm_data_o   = s_axis_c2h_ctrl_imm_data_i;
assign s_axis_c2h_tvalid_o          = (user_l3fwd_mode & pkt_in_flight) ? 1'b0 : s_axis_c2h_tvalid_i; // Throttle if it's in single packet mode
assign s_axis_c2h_tready_i          = (user_l3fwd_mode & pkt_in_flight) ? 1'b0 : s_axis_c2h_tready_o; // Throttle if it's in single packet mode
assign s_axis_c2h_tlast_o           = s_axis_c2h_tlast_i;
assign s_axis_c2h_mty_o             = s_axis_c2h_mty_i;

// H2C
assign m_axis_h2c_tdata_o           = m_axis_h2c_tdata_i;
assign m_axis_h2c_dpar_o            = m_axis_h2c_dpar_i;
assign m_axis_h2c_tvalid_o          = m_axis_h2c_tvalid_i;
assign m_axis_h2c_tready_i          = m_axis_h2c_tready_o;
assign m_axis_h2c_tlast_o           = m_axis_h2c_tlast_i;
assign m_axis_h2c_tuser_qid_o       = m_axis_h2c_tuser_qid_i;
assign m_axis_h2c_tuser_port_id_o   = m_axis_h2c_tuser_port_id_i;
assign m_axis_h2c_tuser_err_o       = m_axis_h2c_tuser_err_i;
assign m_axis_h2c_tuser_mdata_o     = m_axis_h2c_tuser_mdata_i;
assign m_axis_h2c_tuser_mty_o       = m_axis_h2c_tuser_mty_i;
assign m_axis_h2c_tuser_zero_byte_o = m_axis_h2c_tuser_zero_byte_i;

endmodule
