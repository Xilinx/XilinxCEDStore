// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////
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
