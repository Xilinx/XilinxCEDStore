// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////

`ifndef MAILBOX_MSG_MEM_SV
`define MAILBOX_MSG_MEM_SV

`include "mailbox_defines.svh"

`timescale 1ns/1ps

module qdma_v2_0_1_mailbox_msg_mem
  #(
    parameter MEM_W=32,
    parameter ADR_W=9,  
    parameter WBE_W=1,
    parameter PAR_W=MEM_W/8,  
    parameter USE_URAM=0,
    parameter ECC_ENABLE=1,
    parameter RDT_FFOUT=1		// rdt flop-out
  ) (
  input logic                  clk,
  input logic                  rst,    
  input logic  [WBE_W-1:0]     we,
  input logic  [ADR_W-1:0]     wad,
  input logic  [MEM_W-1:0]     wdt,
  input logic  [PAR_W-1:0]     wpar,    
  input logic                  re,
  input logic  [ADR_W-1:0]     rad,
  output logic [MEM_W-1:0]     rdt,
  output logic [PAR_W-1:0]     rpar,    
  output logic                 sbe,
  output logic                 dbe
);

generate if(USE_URAM==0) begin: GEN_MSG_MEM_BRAM

qdma_v2_0_1_mailbox_xpm_sdpram_wrap 
  #(
    .MEM_W         (MEM_W), 
    .ADR_W         (ADR_W), 
    .WBE_W         (1 ), 
    .ECC_ENABLE    (1), 
    .PARITY_ENABLE (0), 
    .RDT_FFOUT     (RDT_FFOUT)           
  ) u_msg_mem_uram(
  .clk (clk ), 
  .rst (rst ), 
  .we  (we  ), 
  .wad (wad ), 
  .wdt (wdt ), 
  .wpar(wpar), 
  .re  (re  ), 
  .rad (rad ), 
  .rdt (rdt ), 
  .rpar(rpar), 
  .sbe (sbe ), 
  .dbe (dbe )
);

end
endgenerate

generate if(USE_URAM==1) begin: GEN_MSG_MEM_URAM
//Notes: Support 32-bit external memory width only
localparam MEMORY_SIZE      = 32 * (2**ADR_W);
localparam MEMORY_PRIMITIVE ="ultra";
localparam ECC_MODE         = ECC_ENABLE ? ((MEMORY_PRIMITIVE == "ultra")        ? "both_encode_and_decode" :
                                            (MEMORY_PRIMITIVE == "block")        ? "both_encode_and_decode" :
                                                                                   "no_ecc")      : 
                                                                                   "no_ecc";
wire [2*MEM_W-1:0] wdt_2x = {wdt,wdt};
wire [2*MEM_W-1:0] rdt_2x ;
wire [64/8-1:0]    wea;

logic[31:0]        rdt_out;
logic              re_ff;

wire   wad_h =  wad[0];
wire   wad_l = ~wad[0];
assign wea   = {{4{wad_h}}, {4{wad_l}}}; 

always_ff@(posedge clk)
  if(rst) 
    re_ff <= '0;
  else 
    re_ff <= re;

always_ff@(posedge clk)
  if(rst) 
    rdt_out <= '0;
  else
    rdt_out <= ~re_ff ? rdt_out :
               rad[0] ? rdt_2x[63:32] : rdt_2x[31:0];

assign rdt  = rdt_out;
assign rpar = '0;


        xpm_memory_sdpram # (
        
          // Common module parameters
          .MEMORY_SIZE             (MEMORY_SIZE),           //positive integer
          .MEMORY_PRIMITIVE        (MEMORY_PRIMITIVE),      //string; "auto", "distributed", "block" or "ultra";
          .CLOCKING_MODE           ("common_clock"),        //string; "common_clock", "independent_clock" 
          .MEMORY_INIT_FILE        ("none"),                //string; "none" or "<filename>.mem" 
          .MEMORY_INIT_PARAM       (""    ),                //string;
          .USE_MEM_INIT            (1),                     //integer; 0,1
          .WAKEUP_TIME             ("disable_sleep"),       //string; "disable_sleep" or "use_sleep_pin" 
          .MESSAGE_CONTROL         (0),                     //integer; 0,1
          .ECC_MODE                (ECC_MODE),              //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
          .AUTO_SLEEP_TIME         (0),                     //Do not Change
        //  .USE_EMBEDDED_CONSTRAINT (0),                     //integer: 0,1
        
          // Port A module parameters
          .WRITE_DATA_WIDTH_A      (64),     //positive integer
          .BYTE_WRITE_WIDTH_A      (8),     //integer; 8, 9, or WRITE_DATA_WIDTH_A value
          .ADDR_WIDTH_A            (ADR_W-1),                 //positive integer
        
          // Port B module parameters
          .READ_DATA_WIDTH_B       (64),     //positive integer
          .ADDR_WIDTH_B            (ADR_W-1),                 //positive integer
          .READ_RESET_VALUE_B      ("0"),                   //string
          .READ_LATENCY_B          (1),        //non-negative integer
          .WRITE_MODE_B            ("read_first")           //string; "write_first", "read_first", "no_change" 
        
        ) u_msg_mem_bram (
        
          // Common module ports
          .sleep          (1'b0),
          // Port A module ports
          .clka           (clk),
          .ena            (we),
          .wea            (wea),
          .addra          (wad[ADR_W-1:1]),
          .dina           (wdt_2x),
          .injectsbiterra (1'b0),
          .injectdbiterra (1'b0),
          // Port B module ports
          .clkb           (clk),
          .rstb           (rst),
          .enb            (re),
          .regceb         (re),
          .addrb          (rad[ADR_W-1:1]),
          .doutb          (rdt_2x),
          .sbiterrb       (sbe),
          .dbiterrb       (dbe)
        );


end
endgenerate

endmodule 

`endif   // MAILBOX_XPM_SDPRAM_WRAP_SV
				
