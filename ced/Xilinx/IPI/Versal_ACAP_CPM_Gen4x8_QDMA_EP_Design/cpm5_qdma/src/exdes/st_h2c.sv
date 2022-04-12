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
// File       : st_h2c.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps
//
// Stream H2C
//
module ST_h2c #
   ( parameter BIT_WIDTH = 64,
     C_H2C_TUSER_WIDTH = 55,
     parameter PATT_WIDTH = 16
    )
    ( input  axi_aclk,
      input  axi_aresetn,
      input [31:0] control_reg,
      input  control_run,
      input  [31:0] h2c_txr_size,
      input  [BIT_WIDTH-1:0] h2c_tdata,
      input  h2c_tvalid,
      input  h2c_tlast,
      input   [10:0] h2c_tuser_qid /* synthesis syn_keep = 1 */,
      input   [2:0]  h2c_tuser_port_id, 
      input          h2c_tuser_err, 
      input   [31:0] h2c_tuser_mdata, 
      input   [5:0]  h2c_tuser_mty, 
      input          h2c_tuser_zero_byte, 
      input  clr_match,
      output reg h2c_tready,
      output reg [31:0] h2c_count,
      output h2c_match
    );

localparam INC_DATA = (BIT_WIDTH == 64 ) ? 8 : (BIT_WIDTH == 128 ) ? 16 : (BIT_WIDTH == 256 ) ? 32 : 64;   // Total bytes per beat
//Increment pattern every 8bits or 16 bits.
localparam PAT_INC = (PATT_WIDTH == 16) ? ((BIT_WIDTH == 64 ) ? 4 : (BIT_WIDTH == 128 ) ? 8 : (BIT_WIDTH == 256 ) ? 16 : 32)
                                             :((BIT_WIDTH == 64 ) ? 8 : (BIT_WIDTH == 128 ) ? 16 : (BIT_WIDTH == 256 ) ? 32 : 64); // Total bytes per beat
   localparam TCQ = 1;
   
   reg [ PATT_WIDTH-1:0] dat[0:63];
   wire tkeep_all1;
   wire tkeep_half1;
   wire tkeep_all0;

   wire [INC_DATA-1:0] cmp_val;
   reg match;
   reg h2c_fail;
   reg 	     control_run_d1;
   reg 	     h2c_tlast_d1, h2c_tlast_d2;
   reg size_match;
   wire [INC_DATA-1:0] h2c_tkeep = {INC_DATA{1'b1}};
   reg [15:0] 	       bp_lfsr;
   wire 	       bp_lfsr_net;
   wire 	       loopback_st;
   wire 	       back_pres;
   wire [5:0] 	       emt_eop = h2c_tuser_mty[5:0];
   wire [5:0] 	       emt_sop = 6'b0;
   wire  	       zero_byte = h2c_tuser_zero_byte;

   // Tuser formate
   // [10:0] Qid
   // [11] wbc
   // [14:12] Port id
   // [15] err
   // [47:16] metadata
   // [53:48] mty
   // [54] zero_byte

   reg [31:0] h2c_count_1;
   reg 	   h2c_tvalid_t1;
   
assign loopback_st = control_reg[0];
assign back_pres   = control_reg[1];

//assign h2c_match = match & size_match;
assign h2c_match = match;

always @(posedge axi_aclk) begin
    if (~axi_aresetn) begin
        control_run_d1 <= 'h0;
        h2c_tlast_d1   <= 'h0;
	h2c_tlast_d2   <= 'h0;
        h2c_tvalid_t1  <= 'h0;
    end
    else begin
        control_run_d1 <= control_run;
        h2c_tlast_d1   <= h2c_tvalid & h2c_tlast;
	h2c_tlast_d2   <= h2c_tlast_d1;
        h2c_tvalid_t1  <= h2c_tvalid;
    end
end

assign bp_lfsr_net = bp_lfsr[0] ^ bp_lfsr[2] ^ bp_lfsr[3] ^ bp_lfsr[5];

always @(posedge axi_aclk) begin
    if (~axi_aresetn) begin
        bp_lfsr <= 16'h0011; // initial seed for back pressure LFSR
        h2c_tready <= 1'b1;
    end
    else begin
        bp_lfsr <= {bp_lfsr_net,bp_lfsr[15:1]};
        h2c_tready <= (back_pres && bp_lfsr[0]) ? 1'b0 : 1'b1; // some random back pressure
    end
end

always @(posedge axi_aclk) begin
    if (~axi_aresetn | clr_match | loopback_st)
        size_match <= 1'b1;
    else if (h2c_tlast_d1)
        size_match <= (((h2c_count_1[19:0]*INC_DATA)/2) == h2c_txr_size[22:0]) ? 1'b1 : 1'b0;
end

always @(posedge axi_aclk) begin
    if (~axi_aresetn | clr_match | loopback_st)
        match <= 1'b0;
    else
//      match <= (h2c_count_1 > 0) ? ~h2c_fail : match;
      match <= (h2c_tlast_d1 & ~h2c_tlast_d2) ? ~h2c_fail : match;
end

always @(posedge axi_aclk) begin
    if (~axi_aresetn | clr_match | loopback_st)
        h2c_fail <= 1'b0;
    else if (h2c_tvalid && h2c_tready && (~&cmp_val) && ~zero_byte)
        h2c_fail <= 1'b1;
end

assign tkeep_all1  = &h2c_tkeep;      // see if all are 1's
assign tkeep_half1 = &h2c_tkeep[BIT_WIDTH/16-1:0];  // see if first half is all 1's
assign tkeep_all0  = ~|h2c_tkeep;     // see if all are 0's 


always @(posedge axi_aclk) begin
   if (~axi_aresetn)
     h2c_count <= 0;
   else if (h2c_tlast_d1)
     h2c_count <= h2c_count_1;
end

always @(posedge axi_aclk) begin
    if (~axi_aresetn | clr_match) begin
        h2c_count_1 <= 0;
        for (integer j=0; j<PAT_INC; j++)
             dat[j] <= #TCQ j;
        end
    else if (h2c_tvalid && h2c_tready) begin
         h2c_count_1 <= h2c_count_1 + 1;
         for (integer j=0; j<PAT_INC; j++)
             dat[j] <= #TCQ dat[j]+PAT_INC;
        end
//    else if (h2c_tvalid && h2c_tready && tkeep_half1 ) begin   // for 512 bits two transfer
//         h2c_count_1 <= h2c_count_1 + 1;
//         for (integer j=0; j<INC_DATA; j++)
//             dat[j] <= #TCQ dat[j]+INC_DATA/2;
//        end
end

wire [255:0] tmp_data = {dat[15],dat[14],dat[13],dat[12],dat[11],dat[10],dat[9],dat[8],dat[7],dat[6],dat[5],dat[4],dat[3],dat[2],dat[1],dat[0]};
   
   wire [5:0] 	       eop_num = h2c_tlast ? (INC_DATA - emt_eop[5:0]) :6'b0;
   wire [5:0] 	       sop_num = h2c_tlast ? (INC_DATA - emt_sop[5:0]) :6'b0;
   
   logic [INC_DATA-1:0] tmp_tkeep;
   
//   assign tmp_tkeep = h2c_tlast ? {{emt_eop{1'b0}},{eop_num{1'b1}}} : {32{1'b1}};
always_comb
  begin
   if (h2c_tlast) begin   // EOP empty bytes  // if sop and eop as same, eop takes prioroty
      for (integer i = 0; i < INC_DATA; i++) begin
	if (i < eop_num)
	  tmp_tkeep[i] = 1'b1;
	else 
	  tmp_tkeep[i] = 1'b0;
     end
   end
   else if (h2c_tvalid & ~h2c_tvalid_t1) begin  // SOP empty bytes
      for (integer i = 0; i < INC_DATA; i++) begin
	if (i < emt_sop)
	  tmp_tkeep[i] = 1'b0;
	else 
	  tmp_tkeep[i] = 1'b1;
      end
   end
   else
     tmp_tkeep = {INC_DATA{1'b1}};
end
   

// Compare data for all bytes in a beat.
//
genvar j;
generate
   for (j = 0; j<INC_DATA; j++) begin : gen_loop
      h2c_slice	#(
	  .PATT_WIDTH (8)
      )
       i_h2c_slice(
	.data_in (h2c_tdata[(8*j)+7:8*j]),  // 7:0,15:8, 23:16
        .tkeep   (tmp_tkeep[j]),
        .value   ((j%2 == 0)? dat[j/2][7:0] : dat[j/2][15:8] ),
        .cmp     (cmp_val[j]));
   end

endgenerate
endmodule

module h2c_slice #
  (
   parameter PATT_WIDTH = 8
   )
   (input [PATT_WIDTH-1:0] data_in,
    input tkeep,
    input [PATT_WIDTH-1:0] value,
    output wire cmp
    );
//wire cmp;
assign cmp = tkeep ? (data_in == value) : 1;

endmodule
