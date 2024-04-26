//-----------------------------------------------------------------------------
//
// (c) Copyright 1986-2022 Xilinx, Inc. All rights reserved.
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
//`include "cdx5n_flop_macros.svh"
`ifndef CDX5N_REG_SLICE
`define CDX5N_REG_SLICE

module cdx5n_reg_slice
#(
parameter	C_DATA_WIDTH    = 32,
parameter       C_REG_PATHS     = 1
)
(
input   				clk,	    
input   				rst_n,	    
input                                   i_s_vld,
input   [C_DATA_WIDTH-1:0]              i_s_dat,
output  logic                           o_s_rdy,

output  logic                           o_m_vld,
output  logic [C_DATA_WIDTH-1:0]        o_m_dat,
input                                   i_m_rdy
);


generate
if(C_REG_PATHS == 0) begin   : NO_FLOPS //No Flops, Just Bypass in both directions

assign o_m_vld = i_s_vld;
assign o_m_dat = i_s_dat;
assign o_s_rdy = i_m_rdy;

end //end of C_REG_PATHS == 0 of generate

else if (C_REG_PATHS == 1) begin : REG_FWD_PATH//Forward Path registering (i.e vld, dat)
logic pre_rdy;
always_ff @(posedge clk or negedge rst_n)
  if(~rst_n) begin
    o_m_vld <= 1'b0;
  end else if(i_s_vld) begin
    o_m_vld <= 1'b1;
  end else if (i_m_rdy) begin
    o_m_vld <= 1'b0;
  end

always_ff @(posedge clk or negedge rst_n)
  if(~rst_n) begin
    o_m_dat <= '0;
  end else begin
    if(i_s_vld & o_s_rdy)
      o_m_dat <= i_s_dat;
  end



always_ff @(posedge clk or negedge rst_n)
   if(~rst_n)
    pre_rdy <= 1'b0;
   else
    pre_rdy <= 1'b1;

assign o_s_rdy = (i_m_rdy | ~o_m_vld) & pre_rdy; 


end //end of C_REG_PATHS == 1 of generate

else begin : REG_BOTH_PATHS //Register Both Forward and Reverse Paths

logic [C_DATA_WIDTH-1:0] pld_hold;

always @(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
       o_s_rdy <= 1'b1;
    else
       o_s_rdy <= (i_m_rdy | ~o_m_vld | (o_s_rdy & ~i_s_vld));
  end

always @(posedge clk or negedge rst_n)
begin
     if(~rst_n)
       o_m_vld <= 1'b0;
     else 
       o_m_vld <= i_s_vld | ~o_s_rdy | (o_m_vld & ~i_m_rdy);
   end

always @(posedge clk or negedge rst_n)
 begin
     if(~rst_n)
      pld_hold <= 'h0;
     else if(o_s_rdy)
      pld_hold <= i_s_dat;
 end

always @(posedge clk or negedge rst_n)
    begin
      if(~rst_n)
	o_m_dat <= 'h0;
      else if(~o_m_vld | i_m_rdy)
        o_m_dat <= o_s_rdy ? i_s_dat : pld_hold;
   end	

end // end of (C_REG_PATHS) else of generate
endgenerate // end of generate

endmodule

`endif
