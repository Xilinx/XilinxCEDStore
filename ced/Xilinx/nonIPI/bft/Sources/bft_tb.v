`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx Inc 
// Engineer: 
//
// Create Date:   14:31:39 12/22/2010
// Design Name:   bft
// Module Name:   bft_tb.v
// Project Name:  
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Bench for module: bft
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module bft_tb;

	// Inputs
	reg wbClk;
	reg bftClk;
	reg reset;
	reg wbDataForInput;
	reg wbWriteOut;
	reg [31:0] wbInputData;

	// Outputs
	wire wbDataForOutput;
	wire [31:0] wbOutputData;
	wire error;

	// Instantiate the Unit Under Test (UUT)
	bft uut (
		.wbClk(wbClk), 
		.bftClk(bftClk), 
		.reset(reset), 
		.wbDataForInput(wbDataForInput),
		.wbWriteOut(wbWriteOut),
		.wbDataForOutput(wbDataForOutput), 
		.wbInputData(wbInputData), 
		.wbOutputData(wbOutputData), 
		.error(error)
	);

	initial begin
		// Initialize Inputs
		wbClk = 0;
		bftClk = 1;
		reset = 1;
		wbDataForInput = 0;
		wbInputData = 0;
        wbWriteOut = 0;
		// Wait 100 ns for global reset to finish
		#100;
      reset = 0;
        
		// Add stimulus here
   end

   initial
      $timeformat (-9, 3, " ns", 13);

   parameter READ_PERIOD = 10;

   initial
      forever
         #(READ_PERIOD/2) wbClk = ~wbClk;
      initial begin
        #500;
        @(posedge wbClk);
        #1 wbWriteOut = 1'b1;
        #300;
        @(posedge wbClk);
        #1 wbWriteOut = 1'b0;
      end  
///   end     

   parameter WRITE_PERIOD = 5;

   initial 
      forever
         #(WRITE_PERIOD/2) bftClk = ~bftClk;
   initial begin
      repeat (100) begin
         #130;
         @(posedge bftClk);
         #1 wbDataForInput = 1'b1;
         @(posedge bftClk);
         #1 wbInputData = wbInputData - 1;
         #80
         @(posedge bftClk);
         wbDataForInput = 1'b0;
      end
   end
endmodule

