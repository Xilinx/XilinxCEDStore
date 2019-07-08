`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2003 Xilinx, Inc.
// All Rights Reserved
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: 12.2
//  \   \         
//  /   /         Filename: async_fifo.v
// /___/   /\     Orig Date: 07/20/2004
// \   \  /  \	  Author: Brian Philofsky
//  \___\/\___\   Last Updated: 07/19/10
//
// Device: All FPGA
// Supported Synthesis Tools: Synplicity or XST
// Design Name: async_fifo
// Purpose:
//    The following is paramatizable RTL code for an asynchronous FIFO
//    which can be simulated in any Verilog 2001 compliant simulator and 
//    implemented in XST or Synplicity synthesis tools targeting Xilinx FPGAs. 
//    This code is provided as a reference for a possible FIFO implementation and 
//    should be properly validated by the end user before using in any FPGA design.  
//    In other words, use at your own risk.
//
// Version: 0.6
//
// Version 0.1 - Initial Code Created
// Version 0.2 - Redesigned addressing and flags
// Version 0.3 - Fixed Dist RAM issues and made almost flags active when empty/full
// Version 0.4 - Added `define and `ifdef for Synplicity added
// Version 0.5 - Added wr_ack output
// Version 0.6 - Removed Synplicity `ifdef since it seems it is no longer needed.
//               Updated port declarations to ANSI style.
////////////////////////////////////////////////////////////////////////////////

module async_fifo #(
   parameter DEVICE = "7SERIES", // "SPARTAN6", "VIRTEX5","VIRTEX6" or "7SERIES"
             FIFO_WIDTH = 144, // Set the FIFO data width	(number of bits)
             FIFO_DEPTH = 12, // Express FIFO depth by power of 2 or number of address bits for the FIFO RAM
                              // i.e. 9 -> 2**9 -> 512 words
             FIRST_WORD_FALL_THROUGH  = "FALSE",
             ALMOST_EMPTY_OFFSET = 9'd32,
             ALMOST_FULL_OFFSET = 9'd121,
				 USE_PROG_FULL_EMPTY = "FALSE", // "TRUE"/"FALSE" Using the programmable full/empty feature can have 
				                               //   a negative affect on performnace and area.
             FLAG_GENERATION = "FAST", // "FAST" or "SAFE"
          //   OPTIMIZE = "PERFORMANCE", // "PERFORMANCE" or "POWER"
             FIFO_RAM_TYPE = "BLOCK_RAM") // "AUTO", "HARDFIFO", "BLOCKRAM" or "DISTRIBUTED_RAM"

(  input [FIFO_WIDTH-1:0] din,
   input rd_clk,
   input rd_en,
   input rst,
   input wr_clk,
   input wr_en,

   output [FIFO_WIDTH-1:0] dout,
   output empty,
   output full,
//   output almost_empty,
//   output almost_full,
   output reg wr_ack,
   output prog_empty,
   output prog_full
);

    initial begin // Note: In XST will error if depth violated.  In Synplify, will be ignored with a warning. xilinx-brianp
	    if (FIFO_RAM_TYPE=="HARDFIFO" && DEVICE=="SPARTAN6") begin
		    $display("Error: Instance %m FIFO_RAM_TYPE set to %s and DEVICE set to %s.  Spartan-6 does not support a HARDFIFO option..", FIFO_RAM_TYPE, DEVICE);
			 $finish;
		 end
	 end


   genvar i;
   generate
      if ((FIFO_RAM_TYPE=="HARDFIFO") || (FIFO_RAM_TYPE=="AUTO" && DEVICE!="SPARTAN6" && (FIFO_DEPTH<14) && (FIFO_DEPTH>5 || (FIFO_DEPTH<=6 && FIFO_WIDTH<=8)))) begin: hard_fifo
      
	    initial begin // Note: In XST will error if depth violated.  In Synplify, will be ignored with a warning. xilinx-brianp
		    if (FIFO_DEPTH > 13) begin
			    $display("Attribute Out of Range Error: Instance %m FIFO_DEPTH must be limited to less than 8192.  Currently set to %d.", FIFO_DEPTH);
				 $finish;
			 end
		 end
	
	    localparam sub_fifo_width = (FIFO_DEPTH<=9) ? 72 :
		                             (FIFO_DEPTH<=10) ? 36 :
		                             (FIFO_DEPTH<=11) ? 18 :
		                             (FIFO_DEPTH<=12) ? 9 :
		                             4;
	
	    localparam num_FIFO_blocks = ((FIFO_WIDTH%sub_fifo_width)==0) ? FIFO_WIDTH/sub_fifo_width :
		                              (FIFO_WIDTH/sub_fifo_width)+1;
	
			wire [num_FIFO_blocks-1:0] almostempties, almostfulls, empties, fulls;
			wire [num_FIFO_blocks-1:0] wrerrs, rderrs;
	
	      for (i=FIFO_WIDTH; i > 0; i=i-sub_fifo_width) 
	      begin: fifo_gen
			
			
				if ((i <= (sub_fifo_width/2)) && (sub_fifo_width != 4)) begin: fifo18_inst
				
					// FIFO_DUALCLOCK_MACRO: Dual Clock First-In, First-Out (FIFO) RAM Buffer
					//                       Virtex-6
					// Xilinx HDL Language Template, version 12.1
					
					FIFO_DUALCLOCK_MACRO  #(
						.ALMOST_EMPTY_OFFSET(ALMOST_EMPTY_OFFSET), // Sets the almost empty threshold
						.ALMOST_FULL_OFFSET(ALMOST_FULL_OFFSET),  // Sets almost full threshold
						.DATA_WIDTH(i),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
						.DEVICE(DEVICE),  // Target device: "VIRTEX5", "VIRTEX6" 
						.FIFO_SIZE ("18Kb"), // Target BRAM: "18Kb" or "36Kb" 
						.FIRST_WORD_FALL_THROUGH (FIRST_WORD_FALL_THROUGH) // Sets the FIFO FWFT to "TRUE" or "FALSE" 
					) FIFO_DUALCLOCK_MACRO_inst (
						.ALMOSTEMPTY(almostempties[0]), // Output almost empty
						.ALMOSTFULL(almostfulls[0]),   // Output almost full
						.DO(dout[i-1:0]),  // Output data
						.EMPTY(empties[0]),             // Output empty
						.FULL(fulls[0]),               // Output full
						.RDCOUNT(),         // Output read count
						.RDERR(rderrs[0]),             // Output read error
						.WRCOUNT(),         // Output write count
						.WRERR(wrerrs[0]),             // Output write error
						.DI(din[i-1:0]),  // Input data
						.RDCLK(rd_clk),             // Input read clock
						.RDEN(rd_en),               // Input read enable
						.RST(rst),                 // Input reset
						.WRCLK(wr_clk),             // Input write clock
						.WREN(wr_en)                // Input write enable
					);
	
					// End of FIFO_DUALCLOCK_MACRO_inst instantiation
	
				end else if (i > sub_fifo_width) begin: fifo36_1_inst
	
					// FIFO_DUALCLOCK_MACRO: Dual Clock First-In, First-Out (FIFO) RAM Buffer
					//                       Virtex-6
					// Xilinx HDL Language Template, version 12.1
					
					FIFO_DUALCLOCK_MACRO  #(
						.ALMOST_EMPTY_OFFSET(ALMOST_EMPTY_OFFSET), // Sets the almost empty threshold
						.ALMOST_FULL_OFFSET(ALMOST_FULL_OFFSET),  // Sets almost full threshold
						.DATA_WIDTH(sub_fifo_width),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
						.DEVICE(DEVICE),  // Target device: "VIRTEX5", "VIRTEX6" 
						.FIFO_SIZE ("36Kb"), // Target BRAM: "18Kb" or "36Kb" 
						.FIRST_WORD_FALL_THROUGH (FIRST_WORD_FALL_THROUGH) // Sets the FIFO FWFT to "TRUE" or "FALSE" 
					) FIFO_DUALCLOCK_MACRO_inst (
						.ALMOSTEMPTY(almostempties[(i/sub_fifo_width)-1]), // Output almost empty
						.ALMOSTFULL(almostfulls[(i/sub_fifo_width)-1]),   // Output almost full
						.DO(dout[i-1:i-sub_fifo_width]),                   // Output data
						.EMPTY(empties[(i/sub_fifo_width)-1]),             // Output empty
						.FULL(fulls[(i/sub_fifo_width)-1]),               // Output full
						.RDCOUNT(),         // Output read count
						.RDERR(rderrs[(i/sub_fifo_width)-1]),             // Output read error
						.WRCOUNT(),         // Output write count
						.WRERR(wrerrs[(i/sub_fifo_width)-1]),             // Output write error
						.DI(din[i-1:i-sub_fifo_width]),                   // Input data
						.RDCLK(rd_clk),             // Input read clock
						.RDEN(rd_en),               // Input read enable
						.RST(rst),                 // Input reset
						.WRCLK(wr_clk),             // Input write clock
						.WREN(wr_en)                // Input write enable
					);
	
					// End of FIFO_DUALCLOCK_MACRO_inst instantiation
	
				end else begin: fifo36_2_inst
	
					// FIFO_DUALCLOCK_MACRO: Dual Clock First-In, First-Out (FIFO) RAM Buffer
					//                       Virtex-6
					// Xilinx HDL Language Template, version 12.1
					
					FIFO_DUALCLOCK_MACRO  #(
						.ALMOST_EMPTY_OFFSET(ALMOST_EMPTY_OFFSET), // Sets the almost empty threshold
						.ALMOST_FULL_OFFSET(ALMOST_FULL_OFFSET),  // Sets almost full threshold
						.DATA_WIDTH(i),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
						.DEVICE(DEVICE),  // Target device: "VIRTEX5", "VIRTEX6" 
						.FIFO_SIZE ("36Kb"), // Target BRAM: "18Kb" or "36Kb" 
						.FIRST_WORD_FALL_THROUGH (FIRST_WORD_FALL_THROUGH) // Sets the FIFO FWFT to "TRUE" or "FALSE" 
					) FIFO_DUALCLOCK_MACRO_inst (
						.ALMOSTEMPTY(almostempties[0]), // Output almost empty
						.ALMOSTFULL(almostfulls[0]),   // Output almost full
						.DO(dout[i-1:0]),                   // Output data
						.EMPTY(empties[0]),             // Output empty
						.FULL(fulls[0]),               // Output full
						.RDCOUNT(),         // Output read count
						.RDERR(rderrs[0]),             // Output read error
						.WRCOUNT(),         // Output write count
						.WRERR(wrerrs[0]),             // Output write error
						.DI(din[i-1:0]),                   // Input data
						.RDCLK(rd_clk),             // Input read clock
						.RDEN(rd_en),               // Input read enable
						.RST(rst),                 // Input reset
						.WRCLK(wr_clk),             // Input write clock
						.WREN(wr_en)                // Input write enable
					);
	
					// End of FIFO_DUALCLOCK_MACRO_inst instantiation
	
				end
	      end
	
		  if (FLAG_GENERATION == "SAFE") begin
			  assign full = |fulls;
			  assign empty = |empties;
			  assign prog_full = |almostfulls;
			  assign prog_empty = |almostempties;
			  assign RDERR = |rderrs;
			  assign WRER = |wrerrs;
		  end else begin
			  assign full = fulls[num_FIFO_blocks-1];
			  assign empty = empties[num_FIFO_blocks-1];
			  assign prog_full = almostfulls[num_FIFO_blocks-1];
			  assign prog_empty = almostempties[num_FIFO_blocks-1];
			  assign RDERR = rderrs[num_FIFO_blocks-1];
			  assign WRER = wrerrs[num_FIFO_blocks-1];
		  end
		  
         always @(posedge wr_clk or posedge rst)
	      if (rst) begin
	         wr_ack <= 1'b0;
	      end
	      else begin
	         wr_ack <= (|wrerrs) & wr_en;
	      end

	
      end
      else begin: infer_fifo

      (* ASYNC_REG="TRUE" *) reg empty_reg = 1'b1,
		                           full_reg =1'b0,
											almost_empty_reg = 1'b1,
											almost_full_reg = 1'b0;

	   reg [FIFO_DEPTH-1:0] wr_addr = {FIFO_DEPTH{1'b0}},
		                     rd_addr = {FIFO_DEPTH{1'b0}},
									next_wr_addr = {{FIFO_DEPTH-1{1'b0}}, 1'b1},
									next_rd_addr = {{FIFO_DEPTH-1{1'b0}}, 1'b1};
	   reg [FIFO_DEPTH:0] wr_addr_tmp = {{FIFO_DEPTH-1{1'b0}}, 2'b11},
		                   rd_addr_tmp = {{FIFO_DEPTH-1{1'b0}}, 2'b11};
	   reg [FIFO_DEPTH-1:0] two_wr_addr = {{FIFO_DEPTH-2{1'b0}}, 2'b11},
		                     two_rd_addr = {{FIFO_DEPTH-2{1'b0}}, 2'b11};
	
	   wire do_read, do_write;
	
	   // Create FIFO Flags
	
	   always @(posedge rd_clk or posedge rst)
	      if (rst) begin
	         empty_reg <= 1'b1;
	         almost_empty_reg <= 1'b1;
	      end
	      else begin
	         empty_reg <= (rd_en & (next_rd_addr==wr_addr)) | (empty_reg & (wr_addr==rd_addr));
	         almost_empty_reg <= empty_reg | (rd_en & (two_rd_addr==wr_addr)) | (next_rd_addr==wr_addr);
	      end
	
	   always @(posedge wr_clk or posedge rst)
	      if (rst) begin
	         full_reg <= 1'b0;
	         almost_full_reg <= 1'b0;
	         wr_ack <= 1'b0;
	      end
	      else begin
	         full_reg <= (wr_en & (next_wr_addr==rd_addr)) | (full_reg & (wr_addr==rd_addr));
	         almost_full_reg <= full_reg | (wr_en & (two_wr_addr==rd_addr)) | (next_wr_addr==rd_addr);
	         wr_ack <= do_write;
	      end


        if (USE_PROG_FULL_EMPTY=="TRUE") begin: prog_full_empty
		    (* ASYNC_REG="TRUE" *) reg prog_empty_reg = 1'b1,
											    prog_full_reg = 1'b0;

				always @(posedge rd_clk or posedge rst)
					if (rst)
						prog_empty_reg <= 1'b0;
					else
						case ({wr_addr_tmp[FIFO_DEPTH], rd_addr_tmp[FIFO_DEPTH]})
						  2'b00  : prog_empty_reg <= (wr_addr_tmp[FIFO_DEPTH-1:0]-rd_addr_tmp[FIFO_DEPTH-1:0])<ALMOST_EMPTY_OFFSET;
						  2'b01  : prog_empty_reg <= (({1'b1,{FIFO_DEPTH-2{1'b0}}}-wr_addr_tmp[FIFO_DEPTH-1:0])+rd_addr_tmp[FIFO_DEPTH-1:0])<ALMOST_EMPTY_OFFSET;
						  2'b10  : prog_empty_reg <= (wr_addr_tmp[FIFO_DEPTH-1:0]+({1'b1,{FIFO_DEPTH-2{1'b0}}}-rd_addr_tmp[FIFO_DEPTH-1:0]))<ALMOST_EMPTY_OFFSET;
						  2'b11  : prog_empty_reg <= (wr_addr_tmp[FIFO_DEPTH-1:0]-rd_addr_tmp[FIFO_DEPTH-1:0])<ALMOST_EMPTY_OFFSET;
						endcase
			
				always @(posedge wr_clk or posedge rst)
					if (rst) 
						prog_full_reg <= 1'b0;
					else
						case ({wr_addr_tmp[FIFO_DEPTH], rd_addr_tmp[FIFO_DEPTH]})
						  2'b00  : prog_full_reg <= (wr_addr_tmp[FIFO_DEPTH-1:0]-rd_addr_tmp[FIFO_DEPTH-1:0])>ALMOST_FULL_OFFSET;
						  2'b01  : prog_full_reg <= (({1'b1,{FIFO_DEPTH-2{1'b0}}}-wr_addr_tmp[FIFO_DEPTH-1:0])+rd_addr_tmp[FIFO_DEPTH-1:0])>ALMOST_FULL_OFFSET;
						  2'b10  : prog_full_reg <= (wr_addr_tmp[FIFO_DEPTH-1:0]+({1'b1,{FIFO_DEPTH-2{1'b0}}}-rd_addr_tmp[FIFO_DEPTH-1:0]))>ALMOST_FULL_OFFSET;
						  2'b11  : prog_full_reg <= (wr_addr_tmp[FIFO_DEPTH-1:0]-rd_addr_tmp[FIFO_DEPTH-1:0])>ALMOST_FULL_OFFSET;
						endcase

            assign prog_empty = prog_empty_reg;
            assign prog_full = prog_full_reg;

		  end else begin: no_prog_full_empty
		  
          assign prog_empty = 1'b0;
          assign prog_full = 1'b0;
			 
		  end

        if (FIRST_WORD_FALL_THROUGH=="TRUE") begin: FWFT
          reg fwft_reg = 1'b1;
          
          always @(posedge rd_clk or posedge rst)
            if (rst)
              fwft_reg <= 1'b1;
             else if (empty)
              fwft_reg <= 1'b1;
             else
				  fwft_reg <= 1'b0;
          
	      assign do_read = (rd_en & ~empty_reg) | (fwft_reg & ~empty_reg);
	      
	    end else begin: no_FWFT 
	    
	      assign do_read = rd_en & ~empty_reg;
	      
       end

	   assign do_write = wr_en & ~full_reg;
      assign empty = empty_reg;
		assign full = full_reg;
//		assign almost_empty = almost_empty_reg;
//		assign almost_full = almost_full_reg;
	
	   // Write Address Generation
	    
	   always @(posedge wr_clk or posedge rst)
	      if (rst) begin
	         wr_addr <= {FIFO_DEPTH{1'b0}};
	         next_wr_addr <= {{FIFO_DEPTH-1{1'b0}}, 1'b1};
				two_wr_addr <= {{FIFO_DEPTH-2{1'b0}}, 2'b11};
				wr_addr_tmp <= {{FIFO_DEPTH-1{1'b0}}, 2'b11};
	      end
	      else if (do_write) begin
	         wr_addr <= next_wr_addr;
	         next_wr_addr <= two_wr_addr;
				two_wr_addr <= (wr_addr_tmp[FIFO_DEPTH-1:0] >> 1) ^ wr_addr_tmp[FIFO_DEPTH-1:0];
				wr_addr_tmp <= wr_addr_tmp + 1'b1;
	      end
	
	   // Read Address Generation
	      
	   always @(posedge rd_clk or posedge rst)
	      if (rst) begin
	         rd_addr <= {FIFO_DEPTH{1'b0}};
	         next_rd_addr <= {{FIFO_DEPTH-1{1'b0}}, 1'b1};
				two_rd_addr <= {{FIFO_DEPTH-2{1'b0}}, 2'b11};
				rd_addr_tmp <= {{FIFO_DEPTH-1{1'b0}}, 2'b11};
	      end
	      else if (do_read) begin
	         rd_addr <= next_rd_addr;
	         next_rd_addr <= two_rd_addr;
				two_rd_addr <= (rd_addr_tmp[FIFO_DEPTH-1:0] >> 1) ^ rd_addr_tmp[FIFO_DEPTH-1:0];
				rd_addr_tmp <= rd_addr_tmp + 1'b1;
	      end
	
	  // RAM Inference Code
	
	      
	      if (FIFO_RAM_TYPE=="DISTRIBUTED_RAM") begin: dist_ram
	      
            (* RAM_STYLE="PIPE_DISTRIBUTED" *)
				reg [FIFO_WIDTH-1:0] fifo_ram [(2**FIFO_DEPTH)-1:0];			 
	         reg [FIFO_WIDTH-1:0] ram_out, fifo_out;
	
				always @(posedge wr_clk)
					if (do_write)
						fifo_ram[wr_addr] <= din;

	         always @(posedge rd_clk or posedge rst)
	         if (rst)
	            fifo_out <= {FIFO_WIDTH{1'b0}};
	         else if (do_read)
	            fifo_out <= ram_out;
	
	         always @*
	            ram_out = fifo_ram[rd_addr];
					
				assign dout = fifo_out;
					
//	      end else if (OPTIMIZE=="POWER")  begin: block_ram_power
//
//            (* RAM_STYLE="BLOCK_POWER2" *)
//				reg [FIFO_WIDTH-1:0] fifo_ram [(2**FIFO_DEPTH)-1:0];				 
//	         reg [FIFO_WIDTH-1:0] fifo_out;
//
//				always @(posedge wr_clk)
//					if (do_write)
//						fifo_ram[wr_addr] <= din;
//
//	         always @(posedge rd_clk)
//	            if (rst)
//	               fifo_out <= {FIFO_WIDTH{1'b0}};
//	            else if (do_read)
//	               fifo_out <= fifo_ram[rd_addr];
//						
//				assign dout = fifo_out;
						
	      end else begin: block_ram_performance

            //(* RAM_STYLE="BLOCK" *)
				reg [FIFO_WIDTH-1:0] fifo_ram [(2**FIFO_DEPTH)-1:0];		 
	         reg [FIFO_WIDTH-1:0] fifo_out;

				always @(posedge wr_clk)
					if (do_write)
						fifo_ram[wr_addr] <= din;

	         always @(posedge rd_clk)
                 if (rst)
	               fifo_out <= {FIFO_WIDTH{1'b0}};
	            else if (do_read)
	               fifo_out <= fifo_ram[rd_addr];
						
				assign dout = fifo_out;
	      end
	 end
   endgenerate	
endmodule
