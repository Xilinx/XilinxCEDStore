
`timescale  1 ns / 1 ps
//-----------------------------------------------------------------------------
//  
//  Copyright (c) 2009 Xilinx Inc.
//
//  Project  : CED based on Microbalze 
//  Module   : uart_rcvr.v
//
//  Description: 
//    This is the UART RX module.
//
//  Parameters: 
//
//  Tasks:
//
//  Internal variables:
//
//  Notes       : 
//    
//
//  Multicycle and False Paths
//    None - this is a testbench file only, and is not intended for synthesis
//

// All times in this testbench are expressed in units of nanoseconds, with a 
// precision of 1ps increments
module uart_rcvr (
  reset,
  serial_clock,
  serial_in,
  char_out,
  char_valid
  );

  input        reset;
  input        serial_clock;
  input        serial_in;
  output [7:0] char_out;
  output       char_valid;
   
  reg    [7:0] count_fsm;
  reg          rcv_active;
  reg    [7:0] char_out;
  reg          char_valid;

always @(posedge serial_clock or posedge reset)
  if (reset)
    rcv_active <= 1'b0;
  else if (!serial_in)
    rcv_active <= 1'b1;
  else if (count_fsm == 8'd152)
    rcv_active <= 1'b0;

always @(posedge serial_clock or posedge reset)
  if (reset)
    count_fsm <= 8'b0;
  else if (rcv_active)
    count_fsm <= count_fsm + 1;
  else
    count_fsm <= 8'b0;

always @(posedge serial_clock or posedge reset)
  if (reset) begin
    char_out <= 8'b0; 
    char_valid <= 1'b0;
  end
  else begin
    if (count_fsm == 8'd24)  char_out[0] <= serial_in;
    if (count_fsm == 8'd40)  char_out[1] <= serial_in;
    if (count_fsm == 8'd56)  char_out[2] <= serial_in;
    if (count_fsm == 8'd72)  char_out[3] <= serial_in;
    if (count_fsm == 8'd88)  char_out[4] <= serial_in;
    if (count_fsm == 8'd104) char_out[5] <= serial_in;
    if (count_fsm == 8'd120) char_out[6] <= serial_in;
    if (count_fsm == 8'd136) char_out[7] <= serial_in;
    char_valid <= (count_fsm == 8'd136);
  end



endmodule
