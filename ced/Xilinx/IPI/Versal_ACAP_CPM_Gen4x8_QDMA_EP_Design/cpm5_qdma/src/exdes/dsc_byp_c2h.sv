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

`timescale 1ps / 1ps

module dsc_byp_c2h
  (
   
   input [1:0] c2h_dsc_bypass,
   input c2h_mm_marker_req,
   output c2h_mm_marker_rsp,
   output logic                                                           c2h_st_marker_rsp,
   input  logic [255:0]                                                   c2h_byp_out_dsc,
   input  logic [2:0]                                                     c2h_byp_out_fmt,
   input  logic                                                           c2h_byp_out_st_mm,
   input  logic [1:0]                                                     c2h_byp_out_dsc_sz,
   input  logic [10:0]                                                    c2h_byp_out_qid,
   input  logic                                                           c2h_byp_out_error,
   input  logic [11:0]                                                    c2h_byp_out_func,
   input  logic [15:0]                                                    c2h_byp_out_cidx,
   input  logic [2:0]                                                     c2h_byp_out_port_id,
   input  logic [6:0]                                                     c2h_byp_out_pfch_tag,
   input  logic                                                           c2h_byp_out_vld,
   output logic                                                           c2h_byp_out_rdy,
   
   output   logic [63:0]                                                    c2h_byp_in_mm_radr,
   output   logic [63:0]                                                    c2h_byp_in_mm_wadr,
   output   logic [15:0]                                                    c2h_byp_in_mm_len,
   output   logic                                                           c2h_byp_in_mm_mrkr_req,
   output   logic                                                           c2h_byp_in_mm_sdi,
   output   logic [10:0]                                                    c2h_byp_in_mm_qid,
   output   logic                                                           c2h_byp_in_mm_error,
   output   logic [11:0]                                                    c2h_byp_in_mm_func,
   output   logic [15:0]                                                    c2h_byp_in_mm_cidx,
   output   logic [2:0]                                                     c2h_byp_in_mm_port_id,
   output   logic                                                           c2h_byp_in_mm_no_dma,
   output   logic                                                           c2h_byp_in_mm_vld,
   input    logic                                                           c2h_byp_in_mm_rdy,

   output   logic [63:0]                                                    c2h_byp_in_st_csh_addr,
   output   logic [10:0]                                                    c2h_byp_in_st_csh_qid,
   output   logic                                                           c2h_byp_in_st_csh_error,
   output   logic [11:0]                                                    c2h_byp_in_st_csh_func,
   output   logic [2:0]                                                     c2h_byp_in_st_csh_port_id,
   output   logic [6:0]                                                     c2h_byp_in_st_csh_pfch_tag,
   output   logic                                                           c2h_byp_in_st_csh_vld,
   input    logic                                                           c2h_byp_in_st_csh_rdy,
   input logic [6:0]   pfch_byp_tag

   );

   wire 								    c2h_csh_byp;
   wire 								    c2h_sim_byp;

   // c2h_csh_byp is used for C2H St Cash Bypass and also C2H MM bypass looback.
   assign c2h_csh_byp = (c2h_dsc_bypass == 2'b01) ? 1'b1 : 1'b0; // 2'b01 : Cache dsc bypass/MM
   assign c2h_sim_byp = (c2h_dsc_bypass == 2'b10) ? 1'b1 : 1'b0; // 2'b10 : Simple dsc_bypass
   
   //c2h_byp_out_fmt == 3'b1 : is marker responce, all other values are reserved

//   assign c2h_st_marker_rsp = c2h_byp_out_rdy & c2h_byp_out_fmt & c2h_byp_out_vld;
   assign c2h_st_marker_rsp = (c2h_byp_out_fmt == 3'b1 ) & c2h_byp_out_vld & ~c2h_byp_out_st_mm;
   assign c2h_mm_marker_rsp = (c2h_byp_out_fmt == 3'b1 ) & c2h_byp_out_vld & c2h_byp_out_st_mm;

   assign c2h_byp_out_rdy        = (c2h_byp_out_fmt == 3'b1) ? 1'b1 :
				   c2h_csh_byp & c2h_byp_out_st_mm ? c2h_byp_in_mm_rdy :
				   c2h_csh_byp & ~c2h_byp_out_st_mm ? c2h_byp_in_st_csh_rdy :
				   c2h_sim_byp & c2h_byp_in_st_csh_rdy;

// MM
   assign c2h_byp_in_mm_mrkr_req = c2h_mm_marker_req;
   assign c2h_byp_in_mm_radr     = c2h_byp_out_dsc[63:0];
   assign c2h_byp_in_mm_wadr     = c2h_byp_out_dsc[191:128];
   assign c2h_byp_in_mm_len      = c2h_byp_out_dsc[79:64];
   assign c2h_byp_in_mm_sdi      = c2h_byp_out_dsc[94];  // eop. send sdi at last desciptor.
   assign c2h_byp_in_mm_qid      = c2h_byp_out_qid;
   assign c2h_byp_in_mm_error    = c2h_byp_out_error;
   assign c2h_byp_in_mm_func     = c2h_byp_out_func;
   assign c2h_byp_in_mm_cidx     = c2h_byp_out_cidx;
   assign c2h_byp_in_mm_port_id  = c2h_byp_out_port_id;
   assign c2h_byp_in_mm_no_dma   = 1'b0;
   assign c2h_byp_in_mm_vld      = c2h_mm_marker_req | (c2h_csh_byp & ~c2h_byp_out_fmt[0] ? c2h_byp_out_st_mm & c2h_byp_out_vld : 1'b0);

//ST Cache/Simple mode
   assign c2h_byp_in_st_csh_addr     = c2h_byp_out_dsc[63:0];
   assign c2h_byp_in_st_csh_qid      = c2h_byp_out_qid;
   assign c2h_byp_in_st_csh_error    = c2h_byp_out_error;
   assign c2h_byp_in_st_csh_func     = c2h_byp_out_func;
   assign c2h_byp_in_st_csh_port_id  = c2h_byp_out_port_id;
   assign c2h_byp_in_st_csh_pfch_tag = c2h_sim_byp ? pfch_byp_tag : c2h_byp_out_pfch_tag;  // for simple bypass use prefetch tag register
   assign c2h_byp_in_st_csh_vld      = c2h_csh_byp | c2h_sim_byp  & ~c2h_byp_out_fmt[0] ? ~c2h_byp_out_st_mm & c2h_byp_out_vld : 1'b0;

endmodule // dsc_bypass

