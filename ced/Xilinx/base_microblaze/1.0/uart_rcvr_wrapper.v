//-----------------------------------------------------------------------------
//  
//  Copyright (c) 2009 Xilinx Inc.
//
//  Project  : CED based on Microbalze 
//  Module   : uart_rcvr_wrapper.v
//
//  Description: 
//    This is the toplevel module for UART RX module.
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


`timescale 1 ns / 1 ps

module uart_rcvr_wrapper
  (
   uart_msgon,
   uart_sin,
   uart_sout,
   clock,
   reset
  );

  parameter C_OUTPUT_FILE = "Uart0.output";

  input 		uart_msgon;
  output 		uart_sin;
  reg 			uart_sin;
  input 		uart_sout;
  input 		clock;
  input 		reset;

  // UART Simulation Terminal Signals
  reg    [15:0] char_out;
  integer       FP;
  wire   [7:0]  uart_char_out;
  reg    [8*52:0]  uart_mem_out;
  reg    [15:0] uart_mem_out_ptr;
  wire          uart_rcvr_valid;

  // Instantiate UART receiver to capture UART outputs
  uart_rcvr uart_rcvr_0
  (
    .reset        (reset),     // I
    .serial_clock (clock), // I
    .serial_in    (uart_sout),        // I
    .char_out     (uart_char_out),    // O [7:0]
    .char_valid   (uart_rcvr_valid)   // O
  );

  // Open file to write out chars sent out by UART inside FPGA
  initial begin
    uart_mem_out_ptr = 16'b0;
    FP = $fopen(C_OUTPUT_FILE,"w");
    if (FP == 0) begin
      $display ("Could Not Open \"%s\" For Writing", C_OUTPUT_FILE);
      $stop;
    end
    //$fclose(FP);
  end

  // Print to display and write to file the char received by UART
  always @ (posedge clock)
    if (uart_rcvr_valid) begin
      // store char received from UART output into array
      //uart_mem_out[uart_mem_out_ptr] = uart_char_out;
      uart_mem_out = {uart_mem_out<<8,uart_char_out};
      uart_mem_out_ptr = uart_mem_out_ptr + 1;
      // open file output to write out char to file for terminal program
      if (FP == 0) begin
        $display ("Could Not Open \"%s\" For Writing", C_OUTPUT_FILE);
	    $stop;
      end
      // append most recent char to end of file
      $fdisplay (FP, "%h", uart_char_out);
      // force flush so terminal can read new updates
      $fflush(FP);
      
      // write out latest char received from UART output to display
      if (uart_msgon) begin
         if(uart_mem_out_ptr == 16'd26) begin
            $display ("UART OUTPUT: = %s", uart_mem_out);
            $display ("Simulation completed");
            $stop;
         end
      end
       
    end

    initial begin
    
       uart_sin = 1'b1;
       #1700  $display ("Simulation is running, wait till simulation completes");
    end
 
endmodule
