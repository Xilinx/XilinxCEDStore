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
module qdma_qsts
 (
    input            axi_aresetn,
    input            axi_aclk,
    input [7:0]      qsts_out_op,
    input [63:0]     qsts_out_data,
    input [2:0]      qsts_out_port_id,
    input [12:0]     qsts_out_qid,
    input            qsts_out_vld,
    output           qsts_out_rdy,
    input            c2h_st_marker_req,
    input            c2h_mm_marker_req,
    input            h2c_st_marker_req,
    input            h2c_mm_marker_req,
    output logic     c2h_st_marker_rsp,
    output logic     c2h_mm_marker_rsp,
    output logic     h2c_st_marker_rsp,
    output logic     h2c_mm_marker_rsp
 );
// Marker responce from QSTS interface.
   assign qsts_out_rdy = 1'b1;   // ready is always asserted
   always @(posedge axi_aclk ) begin
      if (~axi_aresetn) begin
         c2h_st_marker_rsp <= 1'b0;
         h2c_st_marker_rsp <= 1'b0;
         c2h_mm_marker_rsp <= 1'b0;
         h2c_mm_marker_rsp <= 1'b0;
         end
      else begin
         c2h_st_marker_rsp <= (c2h_st_marker_req & qsts_out_vld & (qsts_out_op == 8'h0)) ? 1'b1 : ~ c2h_st_marker_req ? 1'b0 : c2h_st_marker_rsp;
         h2c_st_marker_rsp <= (h2c_st_marker_req & qsts_out_vld & (qsts_out_op == 8'h1)) ? 1'b1 : ~ h2c_st_marker_req ? 1'b0 : h2c_st_marker_rsp;
         c2h_mm_marker_rsp <= (c2h_mm_marker_req & qsts_out_vld & (qsts_out_op == 8'h2)) ? 1'b1 : ~ c2h_mm_marker_req ? 1'b0 : c2h_mm_marker_rsp;
         h2c_mm_marker_rsp <= (h2c_mm_marker_req & qsts_out_vld & (qsts_out_op == 8'h3)) ? 1'b1 : ~ h2c_mm_marker_req ? 1'b0 : h2c_mm_marker_rsp;
         end
      end
endmodule
