// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
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

//
// Project    : Versal PCI Express Integrated Block
// File       : BMD_AXIST_RQ_512.sv
// Version    : 1.0 
//-----------------------------------------------------------------------------

`include "pcie_app_versal_bmd.vh"
`timescale 1ps / 1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_RQ_512 #(
   parameter         AXISTEN_IF_REQ_ALIGNMENT_MODE = 0,
   parameter         AXISTEN_IF_RQ_STRADDLE        = 0,
   parameter         AXISTEN_IF_REQ_PARITY_CHECK   = 0,
   parameter         AXISTEN_IF_ENABLE_CLIENT_TAG  = 0,
   parameter         RQ_AVAIL_TAG_IDX              = 8,
   parameter         RQ_AVAIL_TAG                  = 256,   
   parameter         RQ_AVAIL_SEQ_NUM_IDX          = 6,
   parameter         RQ_AVAIL_SEQ_NUM              = 64,
   parameter         AXI4_CQ_TUSER_WIDTH           = 183,
   parameter         AXI4_CC_TUSER_WIDTH           = 81,
   parameter         AXI4_RQ_TUSER_WIDTH           = 183,
   parameter         AXI4_RC_TUSER_WIDTH           = 161,
   parameter         TCQ                           = 1
)(
   // Clock and Reset
   input                            user_clk,
   input                            reset_n,
   input                            init_rst_i,

   // AXI-S Requester Request Interface
   output logic [511:0]             s_axis_rq_tdata,
   output logic [15:0]              s_axis_rq_tkeep,
   output logic                     s_axis_rq_tlast,
   output logic                     s_axis_rq_tvalid,
   output logic [AXI4_RQ_TUSER_WIDTH-1:0]             s_axis_rq_tuser,
   input                            s_axis_rq_tready,

   // Client Tag
   input                            client_tag_released_0,
   input                            client_tag_released_1,
   input                            client_tag_released_2,
   input                            client_tag_released_3,

   input        [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_0,
   input        [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_1,
   input        [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_2,
   input        [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_3,

   output logic                     tags_all_back,

   input       [5:0]                pcie_rq_seq_num0,
   input                            pcie_rq_seq_num_vld0,
   input       [5:0]                pcie_rq_seq_num1,
   input                            pcie_rq_seq_num_vld1,

   input                            mwr_start_i,
   input        [10:0]              mwr_len_i,
   input        [31:0]              mwr_addr_i,
   input        [31:0]              mwr_data_i,
   input        [15:0]              mwr_count_i,
   input        [7:0]               mwr_wrr_cnt_i,
   output logic                     mwr_done_o,

   input                            mrd_start_i,
   input        [10:0]              mrd_len_i,
   input        [31:0]              mrd_addr_i,
   input        [15:0]              mrd_count_i,
   input        [7:0]               mrd_wrr_cnt_i,
   output logic                     mrd_done_o,
  
   input        [3:0]               wait_trn_time_i
);
  `ifdef IGNORE_SEQ_NUM
  localparam SEQ_NUM_IGNORE      = 1;
  `else
  localparam SEQ_NUM_IGNORE      = 0;
  `endif

   `STRUCT_AXI_RQ_IF

   s_axis_rq_tdata_512  s_axis_rq_tdata_w;
   logic [15:0]   s_axis_rq_tkeep_w;
   logic          s_axis_rq_tlast_w;
   logic          s_axis_rq_tvalid_w;
   s_axis_rq_tuser_512  s_axis_rq_tuser_w;
   logic          s_axis_rq_tready_w;

   s_axis_rq_tdata_512  s_axis_rq_tdata_r;
   logic [15:0]   s_axis_rq_tkeep_r;
   logic          s_axis_rq_tlast_r;
   logic          s_axis_rq_tvalid_r;
   s_axis_rq_tuser_512  s_axis_rq_tuser_r;
   logic          s_axis_rq_tready_r;

   logic                             seq_num_assigned_0;
   logic                             seq_num_assigned_1; 
   logic [RQ_AVAIL_SEQ_NUM_IDX-1:0]  seq_num_assigned_num_0;
   logic [RQ_AVAIL_SEQ_NUM_IDX-1:0]  seq_num_assigned_num_1; 
   logic [RQ_AVAIL_SEQ_NUM_IDX-1:0]  seq_num_assigned_num_0_q;
   logic [RQ_AVAIL_SEQ_NUM_IDX-1:0]  seq_num_assigned_num_1_q; 
   logic [RQ_AVAIL_SEQ_NUM-1:0]      avail_seq_num;
   logic [RQ_AVAIL_SEQ_NUM-1:0]      seq_num_assigned_vec_0;
   logic [RQ_AVAIL_SEQ_NUM-1:0]      seq_num_assigned_vec_1;
   logic [RQ_AVAIL_SEQ_NUM-1:0]      seq_num_released_vec_0;
   logic [RQ_AVAIL_SEQ_NUM-1:0]      seq_num_released_vec_1;
   logic [RQ_AVAIL_SEQ_NUM_IDX-1:0]  curr_seq_num;
   logic                             mrd_done_int;
   logic                             mwr_done_int;
   logic [5:0]                       s_axis_rq_tuser_seq_num;
   logic    seq_num_all_back;


   genvar var_i;
   generate
      for (var_i = 0; var_i < RQ_AVAIL_SEQ_NUM; var_i = var_i + 1) begin: gen_seq_vec
         assign seq_num_assigned_vec_0[var_i]   = (seq_num_assigned_num_0  == var_i);
         assign seq_num_assigned_vec_1[var_i]   = (seq_num_assigned_num_1  == var_i);
         assign seq_num_released_vec_0[var_i]   = (pcie_rq_seq_num0 == var_i);
         assign seq_num_released_vec_1[var_i]   = (pcie_rq_seq_num1 == var_i);
      end   
   endgenerate

   always @ (posedge user_clk)
   begin
     if (!reset_n)
     begin
       seq_num_assigned_num_0_q <= 'b0;
       seq_num_assigned_num_1_q <= 'b0;
       curr_seq_num             <= 'd1;             // Skipping the seq number 0 - used for read requests
     end
     else
     begin
       seq_num_assigned_num_0_q <= seq_num_assigned_num_0;
       seq_num_assigned_num_1_q <= seq_num_assigned_num_1;

       // Skipping the seq number "0" while incrementing the seq; 
       //incrementing 3f to 1 for +1 increment
       //incrementing 3f to 2 for +2 increment
       //incrementing 3e to 1 for +2 increment
       curr_seq_num             <= ({seq_num_assigned_1, seq_num_assigned_0} == 2'b11) ? (&curr_seq_num[5:1] ? ('d1 + curr_seq_num[0]): (curr_seq_num + 2'd2)) :
                                   ({seq_num_assigned_1, seq_num_assigned_0} == 2'b10) ? (&curr_seq_num[5:0] ?  'd1                   : (curr_seq_num + 2'd1)) : 
                                   ({seq_num_assigned_1, seq_num_assigned_0} == 2'b01) ? (&curr_seq_num[5:0] ?  'd1                   : (curr_seq_num + 2'd1)) : curr_seq_num ;   
     end
   end
   
   assign seq_num_assigned_num_0 = curr_seq_num;
   assign seq_num_assigned_num_1 = ({seq_num_assigned_1, seq_num_assigned_0} == 2'b11) ? (curr_seq_num + 1'b1) : curr_seq_num;

   always @ (posedge user_clk)
   begin
     if (!reset_n)
       avail_seq_num  <= {RQ_AVAIL_SEQ_NUM{1'b1}};
     else if (init_rst_i)
       avail_seq_num  <= {RQ_AVAIL_SEQ_NUM{1'b1}};
     else
       avail_seq_num  <= (avail_seq_num
                                    & ~({RQ_AVAIL_SEQ_NUM{seq_num_assigned_0}} & seq_num_assigned_vec_0)
                                    & ~({RQ_AVAIL_SEQ_NUM{seq_num_assigned_1}} & seq_num_assigned_vec_1)
                                    |  ({RQ_AVAIL_SEQ_NUM{pcie_rq_seq_num_vld0}} & seq_num_released_vec_0)
                                    |  ({RQ_AVAIL_SEQ_NUM{pcie_rq_seq_num_vld1}} & seq_num_released_vec_1));
   end
 
   assign seq_num_all_back = &avail_seq_num[RQ_AVAIL_SEQ_NUM-1:1]; 
   assign mwr_done_o       = (seq_num_all_back | SEQ_NUM_IGNORE) & mwr_done_int;   
   assign mrd_done_o       = /*(seq_num_all_back | SEQ_NUM_IGNORE) & */ mrd_done_int; // Seq num not implemented for read
 

   // Write Engine
   BMD_AXIST_RQ_WRITE_512 #(
      .AXISTEN_IF_REQ_ALIGNMENT_MODE   ( AXISTEN_IF_REQ_ALIGNMENT_MODE ),
      .AXISTEN_IF_RQ_STRADDLE          ( AXISTEN_IF_RQ_STRADDLE ),
      .AXISTEN_IF_REQ_PARITY_CHECK     ( AXISTEN_IF_REQ_PARITY_CHECK ),
      .AXI4_CQ_TUSER_WIDTH             ( AXI4_CQ_TUSER_WIDTH ),
      .AXI4_CC_TUSER_WIDTH             ( AXI4_CC_TUSER_WIDTH ),
      .AXI4_RQ_TUSER_WIDTH             ( AXI4_RQ_TUSER_WIDTH ),
      .AXI4_RC_TUSER_WIDTH             ( AXI4_RC_TUSER_WIDTH ),
      .SEQ_NUM_IGNORE                  ( SEQ_NUM_IGNORE ),
      .TCQ                             ( TCQ )
   ) EP_RQ_W_512 (
      .user_clk                                 ( user_clk ),
      .reset_n                                  ( reset_n ),
      .init_rst_i                               ( init_rst_i ),
            
      // AXI-S Master Request Interface
      .s_axis_rq_tdata                          ( s_axis_rq_tdata_w ),
      .s_axis_rq_tkeep                          ( s_axis_rq_tkeep_w ),
      .s_axis_rq_tlast                          ( s_axis_rq_tlast_w ),
      .s_axis_rq_tvalid                         ( s_axis_rq_tvalid_w ),
      .s_axis_rq_tuser                          ( s_axis_rq_tuser_w ),
      .s_axis_rq_tready                         ( s_axis_rq_tready_w ),
      .curr_seq_num                             ( curr_seq_num ),
      .seq_num_assigned_0                       ( seq_num_assigned_0 ),
      .seq_num_assigned_1                       ( seq_num_assigned_1 ),

      
      .mwr_start_i                              ( mwr_start_i ),
      .mwr_done_o                               ( mwr_done_int ),
      .mwr_addr_i                               ( mwr_addr_i ),
      .mwr_len_i                                ( mwr_len_i ),
      .mwr_count_i                              ( mwr_count_i ),
      .mwr_data_i                               ( mwr_data_i )
   );

   // Read Engine
   BMD_AXIST_RQ_READ_512 #(
      .AXISTEN_IF_REQ_ALIGNMENT_MODE   ( AXISTEN_IF_REQ_ALIGNMENT_MODE ),
      .AXISTEN_IF_RQ_STRADDLE          ( AXISTEN_IF_RQ_STRADDLE ),
      .AXISTEN_IF_REQ_PARITY_CHECK     ( AXISTEN_IF_REQ_PARITY_CHECK ),
      .AXISTEN_IF_ENABLE_CLIENT_TAG    ( AXISTEN_IF_ENABLE_CLIENT_TAG ),
      .RQ_AVAIL_TAG_IDX                ( RQ_AVAIL_TAG_IDX       ),
      .RQ_AVAIL_TAG                    ( RQ_AVAIL_TAG           ),
      .AXI4_CQ_TUSER_WIDTH             ( AXI4_CQ_TUSER_WIDTH ),
      .AXI4_CC_TUSER_WIDTH             ( AXI4_CC_TUSER_WIDTH ),
      .AXI4_RQ_TUSER_WIDTH             ( AXI4_RQ_TUSER_WIDTH ),
      .AXI4_RC_TUSER_WIDTH             ( AXI4_RC_TUSER_WIDTH ),
      .TCQ                             ( TCQ )
   ) EP_RQ_R_512 (
      .user_clk                                 ( user_clk ),
      .reset_n                                  ( reset_n ),
      .init_rst_i                               ( init_rst_i ),
            
      // AXI-S Master Request Interface
      .s_axis_rq_tdata                          ( s_axis_rq_tdata_r ),
      .s_axis_rq_tkeep                          ( s_axis_rq_tkeep_r ),
      .s_axis_rq_tlast                          ( s_axis_rq_tlast_r ),
      .s_axis_rq_tvalid                         ( s_axis_rq_tvalid_r ),
      .s_axis_rq_tuser                          ( s_axis_rq_tuser_r ),
      .s_axis_rq_tready                         ( s_axis_rq_tready_r ),
      
      // Client Tag
      .client_tag_released_0                    ( client_tag_released_0 ),
      .client_tag_released_1                    ( client_tag_released_1 ),
      .client_tag_released_2                    ( client_tag_released_2 ),
      .client_tag_released_3                    ( client_tag_released_3 ),

      .client_tag_released_num_0                ( client_tag_released_num_0 ),
      .client_tag_released_num_1                ( client_tag_released_num_1 ),
      .client_tag_released_num_2                ( client_tag_released_num_2 ),
      .client_tag_released_num_3                ( client_tag_released_num_3 ),

      .tags_all_back                            ( tags_all_back ),

      .mrd_start_i                              ( mrd_start_i ),
      .mrd_done_o                               ( mrd_done_int ),
      .mrd_addr_i                               ( mrd_addr_i ),
      .mrd_len_i                                ( mrd_len_i ),
      .mrd_count_i                              ( mrd_count_i )
   );

   // TX MUX
   BMD_AXIST_RQ_MUX_512 #(
      .AXISTEN_IF_REQ_ALIGNMENT_MODE   ( AXISTEN_IF_REQ_ALIGNMENT_MODE ),
      .AXISTEN_IF_RQ_STRADDLE          ( AXISTEN_IF_RQ_STRADDLE ),
      .AXI4_CQ_TUSER_WIDTH             ( AXI4_CQ_TUSER_WIDTH ),
      .AXI4_CC_TUSER_WIDTH             ( AXI4_CC_TUSER_WIDTH ),
      .AXI4_RQ_TUSER_WIDTH             ( AXI4_RQ_TUSER_WIDTH ),
      .AXI4_RC_TUSER_WIDTH             ( AXI4_RC_TUSER_WIDTH ),
      .TCQ                             ( TCQ )
   ) EP_RQ_MUX_512 (
      .user_clk                                 ( user_clk ),
      .reset_n                                  ( reset_n ),
      .init_rst_i                               ( init_rst_i ),

      // BMD Configuration
      .mwr_wrr_cnt_i                            ( mwr_wrr_cnt_i ),
      .mrd_wrr_cnt_i                            ( mrd_wrr_cnt_i ),
      .wait_trn_time_i                          ( wait_trn_time_i ),
            
      // AXI-S Master Write Request Interface
      .s_axis_rq_tdata_w                        ( s_axis_rq_tdata_w ),
      .s_axis_rq_tkeep_w                        ( s_axis_rq_tkeep_w ),
      .s_axis_rq_tlast_w                        ( s_axis_rq_tlast_w ),
      .s_axis_rq_tvalid_w                       ( s_axis_rq_tvalid_w ),
      .s_axis_rq_tuser_w                        ( s_axis_rq_tuser_w ),
      .s_axis_rq_tready_w                       ( s_axis_rq_tready_w ),

      // AXI-S Master Read Request Interface
      .s_axis_rq_tdata_r                        ( s_axis_rq_tdata_r ),
      .s_axis_rq_tkeep_r                        ( s_axis_rq_tkeep_r ),
      .s_axis_rq_tlast_r                        ( s_axis_rq_tlast_r ),
      .s_axis_rq_tvalid_r                       ( s_axis_rq_tvalid_r ),
      .s_axis_rq_tuser_r                        ( s_axis_rq_tuser_r ),
      .s_axis_rq_tready_r                       ( s_axis_rq_tready_r ),

      // AXI-S Master Read Request Interface
      .s_axis_rq_tdata_o                        ( s_axis_rq_tdata ),
      .s_axis_rq_tkeep_o                        ( s_axis_rq_tkeep ),
      .s_axis_rq_tlast_o                        ( s_axis_rq_tlast ),
      .s_axis_rq_tvalid_o                       ( s_axis_rq_tvalid ),
      .s_axis_rq_tuser_o                        ( s_axis_rq_tuser ),
      .s_axis_rq_tready_i                       ( s_axis_rq_tready )
   );

endmodule // BMD_AXIST_RQ_512
