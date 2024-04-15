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
// File       : perf_cntr.sv
// Version    : 5.0
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps

module perf_cntr #(
  parameter C_CNTR_WIDTH  = 32,  // Counter bit width
  parameter TCQ           = 1
)
(

  // Global
  input                         user_clk,
  
  // Control Signals
  input  [C_CNTR_WIDTH-1:0]     user_cntr_max,  // Set the size of measurement window (clock cycle). All counters reset once free_cnts reaches <user_cntr_max>.
  input                         user_cntr_rst,  // 1 = Reset all counters. 0 = Running
  input                         user_cntr_read, // 1 = Measurement value is read. 0 = _o output registers will only be updated once until user_cntr_read is pulsed again.
  
  // Measurement Signals
  output reg [C_CNTR_WIDTH-1:0] free_cnts_o,    // Copy of free_cnts when trigger is set.
  output reg [C_CNTR_WIDTH-1:0] idle_cnts_o,    // Copy of idle_cnts when trigger is set.
  output reg [C_CNTR_WIDTH-1:0] busy_cnts_o,    // Copy of busy_cnts when trigger is set.
  output reg [C_CNTR_WIDTH-1:0] actv_cnts_o,    // Copy of actv_cnts when trigger is set.
  
  // Probes
  input                         valid,          // AXI Valid
  input                         ready           // AXI Ready

);

reg [C_CNTR_WIDTH-1:0] free_cnts;  // Free running counter for each measurement window; it indicates the counts value at 100% interface utilization
reg [C_CNTR_WIDTH-1:0] idle_cnts;  // Number of clock cycle where valid is low (regardless of ready) for each measurement window
reg [C_CNTR_WIDTH-1:0] busy_cnts;  // Number of clock cycle where valid is high but ready is low for each measurement window
reg [C_CNTR_WIDTH-1:0] actv_cnts;  // Number of clock cycle where valid and ready are high for each measurement window

wire                   trigger;    // Counters' trigger point
reg                    cntr_read;  // Counters were read so we can store a new value in the output registers

/* Performance Counter is used to measure the ratio of link idle and active transfer (percent bus utilization).
   It does not measure the data rate (Bytes/seconds) although it can be calculated by user by assuming an ideal link bandwidth for that particular line rate and width.
   Counters continuously measure performance and reset once free_cnts reaches <user_cntr_max>.
   
   Usage:
   1) Set user_cntr_max to the sample window size you desire.
   2) Set user_cntr_rst to clear and sync all counters
   3) Read all the counter values
   4) Pulse user_cntr_read and repeat from step #3 to get a new measurement.
*/

assign trigger = (free_cnts == user_cntr_max) ? 1'b1 : 1'b0;

always @(posedge user_clk) begin
  if (user_cntr_rst) begin
    
    free_cnts   <= #TCQ 'h0;
    idle_cnts   <= #TCQ 'h0;
    busy_cnts   <= #TCQ 'h0;
    actv_cnts   <= #TCQ 'h0;
    
    cntr_read   <= #TCQ 1'b1;
    
  end else begin
  
    if (trigger) begin
      free_cnts   <= #TCQ 'h0;
      idle_cnts   <= #TCQ 'h0;
      busy_cnts   <= #TCQ 'h0;
      actv_cnts   <= #TCQ 'h0;
      
      cntr_read   <= #TCQ 1'b0;
    end else begin
  
      free_cnts   <= #TCQ free_cnts + 1;
      idle_cnts   <= #TCQ (~valid)         ? (idle_cnts + 1) : idle_cnts;
      busy_cnts   <= #TCQ (~ready & valid) ? (busy_cnts + 1) : busy_cnts;
      actv_cnts   <= #TCQ (ready & valid)  ? (actv_cnts + 1) : actv_cnts;
    
      cntr_read   <= #TCQ user_cntr_read ? 1'b1 : cntr_read;
    end
    
  end
end

// Sample counter values for reading
always @(posedge user_clk) begin
  if (user_cntr_rst) begin
    free_cnts_o <= #TCQ 'h0;
    idle_cnts_o <= #TCQ 'h0;
    busy_cnts_o <= #TCQ 'h0;
    actv_cnts_o <= #TCQ 'h0;
  end else begin
    free_cnts_o     <= #TCQ (cntr_read & trigger) ? free_cnts : free_cnts_o;
    idle_cnts_o     <= #TCQ (cntr_read & trigger) ? idle_cnts : idle_cnts_o;
    busy_cnts_o     <= #TCQ (cntr_read & trigger) ? busy_cnts : busy_cnts_o;
    actv_cnts_o     <= #TCQ (cntr_read & trigger) ? actv_cnts : actv_cnts_o;
  end
end

endmodule
