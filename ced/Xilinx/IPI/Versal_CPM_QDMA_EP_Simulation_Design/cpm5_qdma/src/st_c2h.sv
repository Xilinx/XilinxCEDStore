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
// File       : st_c2h.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

module ST_c2h #
   (
    parameter BIT_WIDTH = 64,
    parameter PATT_WIDTH = 16,

    parameter TM_DSC_BITS = 16
    )
    ( input  axi_aclk,
      input  axi_aresetn,
      input [31:0] control_reg,
      input  [15:0] txr_size,
      input  [10:0] num_pkt,
      input [TM_DSC_BITS-1:0]  credit_in,
      input                    credit_updt,
      input [TM_DSC_BITS-1:0]  credit_perpkt_in,
      input [TM_DSC_BITS-1:0]  credit_needed,
      input [15:0] buf_count,
      output [BIT_WIDTH-1:0] c2h_tdata,
      output [BIT_WIDTH/8-1:0] c2h_dpar,
      output c2h_tvalid,
      output c2h_tlast,
      output c2h_end,
      input  c2h_tready

    );

localparam INC_DATA = (PATT_WIDTH == 16) ? ((BIT_WIDTH == 64 ) ? 4 : (BIT_WIDTH == 128 ) ? 8 : (BIT_WIDTH == 256 ) ? 16 : 32)
                                           :((BIT_WIDTH == 64 ) ? 8 : (BIT_WIDTH == 128 ) ? 16 : (BIT_WIDTH == 256 ) ? 32 : 64); // Total bytes per beat
localparam TCQ = 1;

reg [PATT_WIDTH-1:0] dat[0:INC_DATA-1];
reg [12:0] count;
reg tlast;
reg tvalid;
reg [13:0] max_count;
reg [13:0] u_max_count;
reg [13:0] t_max_count;

localparam [1:0] 
	SM_IDLE = 2'b00,
	SM_TXR  = 2'b01,
	SM_4BK  = 2'b10,
        SM_PKT  = 2'b11;

reg [1:0] sm_c2h;
wire loopback_st;
wire back_pres;
reg [10:0] pkt_count;
reg 	   start_c2h, start_c2h_d1, start_c2h_d2;
reg [TM_DSC_BITS-1:0] credit_used_perpkt;
reg [TM_DSC_BITS-1:0] tcredit_used;
   reg [TM_DSC_BITS-1:0] credit_in_sync;
// wire [15:0] credit_perpkt_in;
reg [5:0] emty_byt_pos;
wire immediate_data;
wire cont_data_st; 
wire lst_credit_pkt; 
   reg 	   control_reg_1_d;
 
assign loopback_st = 0 ;   // bit 0 loopback mode
assign back_pres   = 0 ;   // bit 2, C2H back pressure
assign immediate_data = control_reg[5] ; // only for marker, no c2h data only WB data, only 1 beat.
assign cont_data_st= control_reg[10];   // bit 4, C2H continouts data output stream until all packtes are done
assign c2h_tvalid = tvalid;
assign c2h_tlast = tlast;

//assign credit_perpkt_in = (credit_needed/num_pkt);
assign lst_credit_pkt   = (credit_perpkt_in - credit_used_perpkt) == 1;
		      
always @(posedge axi_aclk) begin
   control_reg_1_d <= control_reg[1];
   t_max_count <= ((txr_size%(BIT_WIDTH/8) > 0) || txr_size == 0 ) ? (txr_size)/(BIT_WIDTH/8) +1 : (txr_size)/(BIT_WIDTH/8);
   emty_byt_pos <=  ((txr_size%(BIT_WIDTH/8) > 0) ? txr_size%(BIT_WIDTH/8) : 6'b0) >> 1; 
end

   assign c2h_end = start_c2h & (num_pkt == pkt_count);
   
always @(posedge axi_aclk)
   if (~axi_aresetn )
     credit_in_sync <= 0;
   else if (~start_c2h )
     credit_in_sync <= 0;
   else if (start_c2h & credit_updt & ~immediate_data)
     credit_in_sync <= credit_in_sync + credit_in ;
     

always @(posedge axi_aclk) begin
   if (~axi_aresetn )
     start_c2h <= 0;
   else if (control_reg_1_d)
     start_c2h <= 1;
   else if (pkt_count >= num_pkt)
     start_c2h <= 0;
end
always @(posedge axi_aclk) begin
  start_c2h_d1 <= start_c2h;
  start_c2h_d2 <= start_c2h_d1;
end

always @(posedge axi_aclk) begin
   if (~axi_aresetn | loopback_st) begin
      sm_c2h <= SM_IDLE;
      tvalid <= 0;
      tlast <= 0;
      count <= 0;
      pkt_count <= 0;
      credit_used_perpkt <= 0;
      tcredit_used <= 0;
      max_count <= 0;
      u_max_count <= 0;
   end
   else
     case (sm_c2h)
       SM_IDLE : begin  // 0
	  if (start_c2h_d1 & ~start_c2h_d2 & immediate_data )
	     sm_c2h <= SM_TXR;
	  else if (start_c2h_d1 & ~start_c2h_d2 && (tcredit_used < credit_in_sync)) begin
	     sm_c2h <= SM_TXR;
	     max_count <= (t_max_count > buf_count) ? buf_count : t_max_count;
	     u_max_count <= t_max_count;
	  end
	  count  <= 0;
	  tvalid <= 0;
	  tlast <= 0;
	  pkt_count <= 0;
	  tcredit_used <= 0;
	  credit_used_perpkt <= 0;
       end
       SM_TXR : begin  // 1
	  if (c2h_tready) begin
	     tvalid<=1;
	     if (immediate_data) begin
	       	tlast <= 1'b1;
	        sm_c2h <= SM_PKT;
	     end
	     else if (count == (max_count - 1) && lst_credit_pkt) begin
		tlast <= 1'b1;
		tcredit_used <= tcredit_used + 1;
		sm_c2h <= SM_PKT;
	     end
	     else if (count == buf_count) begin
		credit_used_perpkt <= credit_used_perpkt+1;
		tcredit_used <= tcredit_used + 1;
		u_max_count <= u_max_count - count;
		count <= 0;
		tvalid<= 1'b0;
		sm_c2h <= SM_4BK;
	     end
	     else begin
		count <= count+1;
	     end
	  end
       end
       SM_4BK : begin  // 2
	  max_count <= (u_max_count > buf_count) ? buf_count : u_max_count;
	  if (c2h_tready & (tcredit_used < credit_in_sync)) begin
	     sm_c2h <= SM_TXR;
	  end
	  else if (tcredit_used == credit_needed) begin
	     sm_c2h <= SM_IDLE;
	     tvalid<= 1'b0;
	     tlast <= 1'b0;
	  end
	  else begin
	     tvalid<= 1'b0;
	  end
       end
       SM_PKT : begin  // 3
	  if (c2h_tready ) begin
	     if (pkt_count == (num_pkt - 1)) begin
		sm_c2h <= SM_IDLE;
		pkt_count <= pkt_count + 1'b1;
	     end
	     else if ( immediate_data ) begin
		pkt_count <= pkt_count + 1'b1;
		sm_c2h <= SM_TXR;
	     end
	     else if ( credit_in_sync > tcredit_used) begin
		pkt_count <= pkt_count + 1'b1;
		sm_c2h <= SM_TXR;
		u_max_count <= t_max_count;
		max_count <= (t_max_count > buf_count) ? buf_count : t_max_count;
	     end
	     else if (tcredit_used == credit_in_sync) begin
		sm_c2h <= SM_PKT;
	     end
	     credit_used_perpkt <= 0;
	     tvalid<= 1'b0;
	     tlast <= 1'b0;
	     count <= 0;
	  end
       end
     endcase // case (sm_c2h)
end
   
   
   
always @(posedge axi_aclk) begin
    if (~axi_aresetn | ~start_c2h | (cont_data_st & tlast)) begin
        for (integer j=0; j<INC_DATA; j++)
             dat[j] <= #TCQ j;
        end
    else if (c2h_tready & tlast & (|emty_byt_pos)) begin  // for continous data acrros different packets
        for (integer j=0; j<INC_DATA; j++)
             dat[j] <= #TCQ dat[emty_byt_pos]+j;
    end
    else if (c2h_tready & tvalid) begin
        for (integer j=0; j<INC_DATA; j++)
             dat[j] <= #TCQ dat[j]+INC_DATA;
        end
end

assign c2h_tdata = (BIT_WIDTH == 64)  ? {dat[3],dat[2],dat[1],dat[0]} :
                   (BIT_WIDTH == 128) ? {dat[7],dat[6],dat[5],dat[4],dat[3],dat[2],dat[1],dat[0]} :
                   (BIT_WIDTH == 256) ? {dat[15],dat[14],dat[13],dat[12],dat[11],dat[10],dat[9],dat[8],dat[7],dat[6],dat[5],dat[4],dat[3],dat[2],dat[1],dat[0]} :
                                        {dat[31],dat[30],dat[29],dat[28],dat[27],dat[26],dat[25],dat[24],dat[23],dat[22],dat[21],dat[20],dat[19],dat[18],dat[17],dat[16],dat[15],dat[14],dat[13],dat[12],dat[11],dat[10],dat[9],dat[8],dat[7],dat[6],dat[5],dat[4],dat[3],dat[2],dat[1],dat[0]};

   logic [BIT_WIDTH/8-1 : 0] dpar_val;
   // Data parity

   assign c2h_dpar = ~dpar_val;
   always_comb begin
      for (integer i=0; i< (BIT_WIDTH/8); i += 1) begin
	 dpar_val[i] = ^c2h_tdata[i*8 +: 8];
      end
   end

endmodule


