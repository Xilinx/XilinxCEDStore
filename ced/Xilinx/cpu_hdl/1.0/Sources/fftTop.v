/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2008 Xilinx, Inc.  All rights reserved.
//
//                 XILINX CONFIDENTIAL PROPERTY
// This   document  contains  proprietary information  which   is
// protected by  copyright. All rights  are reserved.  This notice
// refers to original work by Xilinx, Inc. which may be derivitive
// of other work distributed under license of the authors.  In the
// case of derivitive work, nothing in this notice overrides the
// original author's license agreeement.  Where applicable, the 
// original license agreement is included in it's original 
// unmodified form immediately below this header.
//
// Xilinx, Inc.
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A
// COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
// ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
// STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
// IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
// FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
// XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
// THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
// ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
// FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE.
//
/////////////////////////////////////////////////////////////////////////

`include "timescale.v"

module fftTop (clk,reset,wb_clk,wb_stb_i,wb_dat_o,wb_dat_i,wb_ack_o,
                         wb_adr_i,wb_we_i,wb_cyc_i,wb_sel_i,wb_err_o, wb_rty_o 
			 );

input         clk;
input         reset;
input         wb_clk;
input         wb_stb_i;
wire [31:0] rectify_wb_dat_o;
output [31:0] wb_dat_o;
input  [31:0] wb_dat_i;
output reg       wb_ack_o;
input  [31:0] wb_adr_i;
input         wb_we_i;
input         wb_cyc_i;
input  [3:0]  wb_sel_i;
	 
output        wb_err_o;
output        wb_rty_o;



reg        wb_we_i_reg;
reg        wb_cyc_i_reg;
reg        wb_stb_i_reg;
reg [31:0] wb_dat_i_reg; 
reg [31:0] wb_adr_i_reg, wb_adr_i_reg0; 
reg         fft_read;
wire        fft_done;
reg  [31:0] control_reg;
reg         wb_rty_o;
reg         wb_ack_o_reg;
reg    [3:0] wb_sel_i_reg;


						 
always @(posedge wb_clk)
begin
    wb_cyc_i_reg <= wb_cyc_i;
    wb_stb_i_reg <= wb_stb_i;
    wb_we_i_reg <= wb_we_i;
    wb_dat_i_reg <= wb_dat_i;
    wb_sel_i_reg <= wb_sel_i;
    wb_adr_i_reg0 <= wb_adr_i;
    wb_adr_i_reg <= {wb_adr_i_reg0[31:4],wb_adr_i_reg0[3] ^ wb_sel_i_reg[3], wb_adr_i_reg0[2] ^ wb_sel_i_reg[2], wb_adr_i_reg0[1] ^ wb_sel_i_reg[1], wb_adr_i_reg0[0] ^ wb_sel_i_reg[0]};
	
    wb_rty_o <= control_reg[1] ^ control_reg[3] ^ control_reg[4] ^ control_reg[6] ^ control_reg[17] ^ control_reg[19] ^ control_reg[23] ^ control_reg[29] ^ control_reg[31];
    fft_read <= !wb_stb_i_reg;
end    
												  
												  
												  
always @(posedge wb_clk or posedge reset)
begin
     if(reset==1)
     begin
       wb_ack_o_reg <= 0;
       control_reg <= 32'h0;
       
     end
     else
     begin
       if(fft_done)
       begin
        control_reg[1] <= 1'b1;  
       end
         
       if(wb_stb_i_reg && wb_cyc_i_reg && wb_we_i_reg && ~wb_ack_o_reg)
       begin
         wb_ack_o_reg <= 1;
         case(wb_adr_i_reg[31:0])
             32'h0:
             begin
                 //Writing control register lower
                 control_reg[31:0] <= wb_dat_i_reg;
             end
         endcase
       end
       else if(wb_stb_i_reg && wb_cyc_i_reg && ~wb_we_i_reg && ~wb_ack_o_reg)
       begin
           wb_ack_o_reg <= 1;
           case(wb_adr_i_reg[31:0])
             32'h0:
             begin
                 control_reg[1] <= 1'b0;
             end
           endcase
       end
       else
       begin
           wb_ack_o_reg <= 0;
           control_reg[0] <= 1'b0;
       end
     end
end

bft fftInst (
   .wbClk(clk),
   .bftClk(clk),
   .reset(reset),
   .wbDataForInput(fft_read),
   .wbInputData(wb_dat_i_reg),
   .wbWriteOut(!wb_we_i_reg),
   .wbDataForOutput(fft_done),
   .wbOutputData(rectify_wb_dat_o),
   .error(wb_err_o)
);

	 
always @(posedge wb_clk)
    wb_ack_o <= wb_ack_o_reg;

assign wb_dat_o = rectify_wb_dat_o;	 

endmodule

