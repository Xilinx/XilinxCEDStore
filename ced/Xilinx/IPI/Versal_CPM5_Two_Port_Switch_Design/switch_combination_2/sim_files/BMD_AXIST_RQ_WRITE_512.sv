
//-----------------------------------------------------------------------------
//
// (c) Copyright 1995, 2007, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : Versal PCI Express Integrated Block
// File       : BMD_AXIST_RQ_WRITE_512.sv
// Version    : 1.0 
//-----------------------------------------------------------------------------

`include "pcie_app_versal_bmd.vh"
`timescale 1ps / 1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_RQ_WRITE_512 #(
   parameter         AXISTEN_IF_REQ_ALIGNMENT_MODE = 0,
   parameter         AXISTEN_IF_RQ_STRADDLE        = 0,
   parameter         AXISTEN_IF_REQ_PARITY_CHECK   = 0,
   parameter         AXI4_CQ_TUSER_WIDTH           = 183,
   parameter         AXI4_CC_TUSER_WIDTH           = 81,
   parameter         AXI4_RQ_TUSER_WIDTH           = 183,
   parameter         AXI4_RC_TUSER_WIDTH           = 161,
   parameter         SEQ_NUM_IGNORE                = 0,
   parameter         TCQ                           = 1
)(
   // Clock and Reset
   input                                  user_clk,
   input                                  reset_n,
   input                                  init_rst_i,

   // AXI-S Requester Request Interface
   output logic [511:0]                   s_axis_rq_tdata,
   output logic [15:0]                    s_axis_rq_tkeep,
   output logic                           s_axis_rq_tlast,
   output logic                           s_axis_rq_tvalid,
   output logic [AXI4_RQ_TUSER_WIDTH-1:0] s_axis_rq_tuser,
   input                                  s_axis_rq_tready,
   input        [5:0]                     curr_seq_num,
   output logic                           seq_num_assigned_0,
   output logic                           seq_num_assigned_1,

   input                                  mwr_start_i,
   input        [10:0]                    mwr_len_i,
   input        [31:0]                    mwr_addr_i,
   input        [31:0]                    mwr_data_i,
   input        [15:0]                    mwr_count_i,
   output logic                           mwr_done_o
);
   `STRUCT_AXI_RQ_IF

   logic [29:0]   wr_addr_31_2, wr_addr_31_2_2nd;

   logic [15:0]   total_mwr_count, total_mwr_count_wire;
   logic [11:0]   cur_mwr_dw_count, cur_mwr_dw_count_wire;
   logic [15:0]   w_tcnt, w_tcnt_wire; 
   s_axis_rq_tdata_512  s_axis_rq_tdata_wire;
   s_axis_rq_tdata_512  s_axis_rq_tdata_reg;
   logic [15:0]   s_axis_rq_tkeep_wire;
   logic          s_axis_rq_tlast_wire;
   logic          s_axis_rq_tvalid_wire;
   s_axis_rq_tuser_512  s_axis_rq_tuser_wire;
   s_axis_rq_tuser_512  s_axis_rq_tuser_reg;
   s_axis_rq_tuser_512  s_axis_rq_tuser_w_parity;
   logic [63:0]   s_axis_rq_parity;
   logic          mwr_done_wire;

   localparam  IDLE        = 0;
   localparam  SEND_WHDR   = 1;  // One Write
   localparam  SEND_DATA   = 2;  // Data for Write
   localparam  SEND_DFLH   = 3;  // Data Followed By Header
   localparam  SEND_WSTD   = 4;  // Two Writes
   localparam  LAST        = 5;

   localparam  STATE_CNT   = 6;

   logic [STATE_CNT-1:0]   state_rq, state_rq_wire;

   assign wr_addr_31_2     = mwr_addr_i[31:2] + mwr_len_i[10:0] * w_tcnt[15:0];
   assign wr_addr_31_2_2nd = mwr_addr_i[31:2] + mwr_len_i[10:0] * (w_tcnt[15:0] + 1);

   generate if(AXISTEN_IF_REQ_ALIGNMENT_MODE != "TRUE" )
   begin
     always_comb begin
        total_mwr_count_wire    = total_mwr_count;
        cur_mwr_dw_count_wire   = cur_mwr_dw_count;
        w_tcnt_wire             = w_tcnt;
        s_axis_rq_tdata_wire    = s_axis_rq_tdata_reg;
        s_axis_rq_tkeep_wire    = s_axis_rq_tkeep;
        s_axis_rq_tlast_wire    = s_axis_rq_tlast;
        s_axis_rq_tvalid_wire   = s_axis_rq_tvalid;
        s_axis_rq_tuser_wire    = s_axis_rq_tuser_reg;
        mwr_done_wire           = mwr_done_o;
        state_rq_wire           = 'd0;
        seq_num_assigned_0      = 1'b0;
        seq_num_assigned_1      = 1'b0;

        case (1'b1)
           state_rq[IDLE]: begin
              w_tcnt_wire = 'd0;
              if (mwr_start_i & (mwr_count_i[15:0] != 0) & ~mwr_done_o) begin
                 // Latch all the commands
                 total_mwr_count_wire    = mwr_count_i;
                 cur_mwr_dw_count_wire   = mwr_len_i;
                 if (AXISTEN_IF_RQ_STRADDLE) begin
                    if (mwr_count_i == 1) begin
                          state_rq_wire[SEND_WHDR]   = 1'b1;
                    end else begin // (mwr_count_i != 1)
                       if (mwr_len_i > 4) begin
                          state_rq_wire[SEND_WHDR]   = 1'b1;
                       end else begin // (mwr_len_i <= 4)
                          state_rq_wire[SEND_WSTD]   = 1'b1;
                       end
                    end
                 end else begin // !AXISTEN_IF_RQ_STRADDLE
                    state_rq_wire[SEND_WHDR]   = 1'b1;
                 end
              end else begin // no requests
                 state_rq_wire[IDLE]  = 1'b1;
              end
           end   // IDLE

           state_rq[SEND_WHDR]: begin // One Write
              if (~s_axis_rq_tvalid | s_axis_rq_tready) begin
                 s_axis_rq_tvalid_wire   = 1'b1;
                 s_axis_rq_tdata_wire    = 'd0;
                 s_axis_rq_tuser_wire    = {AXI4_RQ_TUSER_WIDTH{1'b0}};
                 s_axis_rq_tlast_wire    = 1'b0;
                 s_axis_rq_tkeep_wire    = 'd0;

                 seq_num_assigned_0                        = 1'b1;
                 seq_num_assigned_1                        = 1'b0;
                 s_axis_rq_tuser_wire.seq_num0             = SEQ_NUM_IGNORE ? 6'h00 : curr_seq_num;
                 s_axis_rq_tuser_wire.seq_num1             = 6'h00;

                 if (cur_mwr_dw_count > 12) begin
                    s_axis_rq_tdata_wire[511:128]          = {12{mwr_data_i}};
                    s_axis_rq_tdata_wire.lh.req_type       = 4'b0001;
                    s_axis_rq_tdata_wire.lh.dword_count    = mwr_len_i;
                    s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, wr_addr_31_2};
                    s_axis_rq_tuser_wire.last_be           = 8'h0F;
                    s_axis_rq_tuser_wire.first_be          = 8'h0F;
                    if (AXISTEN_IF_RQ_STRADDLE) begin
                       s_axis_rq_tuser_wire.is_sop         = 2'b01;
                    end else begin
                       s_axis_rq_tkeep_wire                = 16'hFFFF;
                    end

                    cur_mwr_dw_count_wire      = cur_mwr_dw_count - 12;
                    if (AXISTEN_IF_RQ_STRADDLE & (cur_mwr_dw_count <= 20) & (total_mwr_count != 1)) begin
                       state_rq_wire[SEND_DFLH]   = 1'b1;  
                    end else begin
                       state_rq_wire[SEND_DATA]   = 1'b1;  
                    end
                 end else begin // (cur_mwr_dw_count <= 12)
                    s_axis_rq_tdata_wire[511:128]          = {12{mwr_data_i}} & ({12{32'hFFFFFFFF}} >> ((12 - cur_mwr_dw_count) * 32));
                    s_axis_rq_tdata_wire.lh.req_type       = 4'b0001;
                    s_axis_rq_tdata_wire.lh.dword_count    = mwr_len_i;
                    s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, wr_addr_31_2};
                    s_axis_rq_tuser_wire.last_be           = (mwr_len_i == 1)? 8'h00: 8'h0F;
                    s_axis_rq_tuser_wire.first_be          = 8'h0F;
                    if (AXISTEN_IF_RQ_STRADDLE) begin
                       s_axis_rq_tuser_wire.is_sop         = 2'b01;
                       s_axis_rq_tuser_wire.is_eop         = 2'b01;
                       s_axis_rq_tuser_wire.is_sop0_ptr    = 2'b00;
                       s_axis_rq_tuser_wire.is_eop0_ptr    = mwr_len_i[3:0] + 3;
                    end else begin
                       s_axis_rq_tlast_wire                = 1'b1;
                       s_axis_rq_tkeep_wire                = 16'hFFFF >> (12 - cur_mwr_dw_count);
                    end

                    // Update flags
                    total_mwr_count_wire       = total_mwr_count - 1;
                    w_tcnt_wire                = w_tcnt + 1;

                    if (total_mwr_count == 1) begin  // All writes are done
                       state_rq_wire[LAST]        = 1'b1;
                    end else begin // (total_mwr_count != 1)
                       cur_mwr_dw_count_wire      = mwr_len_i;
                       state_rq_wire[SEND_WHDR]   = 1'b1;
                    end
                 end
              end else begin // ~s_axis_rq_tready
                 state_rq_wire[SEND_WHDR]   = 1'b1;
              end
           end   // SEND_WHDR

           state_rq[SEND_DATA]: begin
              if (s_axis_rq_tready) begin
                 s_axis_rq_tvalid_wire   = 1'b1;
                 s_axis_rq_tdata_wire    = 'd0;
                 s_axis_rq_tuser_wire    = {AXI4_RQ_TUSER_WIDTH{1'b0}};
                 s_axis_rq_tlast_wire    = 1'b0;
                 s_axis_rq_tkeep_wire    = 'd0;

                 if (cur_mwr_dw_count > 16) begin
                    s_axis_rq_tdata_wire                   = {16{mwr_data_i}};
                    if (~AXISTEN_IF_RQ_STRADDLE) begin
                       s_axis_rq_tkeep_wire                = 16'hFFFF;
                    end

                    cur_mwr_dw_count_wire      = cur_mwr_dw_count - 16;
                    state_rq_wire[SEND_DATA]   = 1'b1;
                 end else begin // (cur_mwr_dw_count <= 16)
                    s_axis_rq_tdata_wire                   = {16{mwr_data_i}} & ({16{32'hFFFFFFFF}} >> ((16 - cur_mwr_dw_count) * 32));
                    if (AXISTEN_IF_RQ_STRADDLE) begin
                       s_axis_rq_tuser_wire.is_eop         = 2'b01;
                       s_axis_rq_tuser_wire.is_eop0_ptr    = cur_mwr_dw_count[3:0] - 1;
                    end else begin
                       s_axis_rq_tlast_wire                = 1'b1;
                       s_axis_rq_tkeep_wire                = 16'hFFFF >> (16 - cur_mwr_dw_count);
                    end

                    // Update flags
                    total_mwr_count_wire       = total_mwr_count - 1;
                    w_tcnt_wire                = w_tcnt + 1;
                    
                    if (total_mwr_count == 1) begin  // All writes are done
                       state_rq_wire[LAST]        = 1'b1;
                    end else begin // (total_mwr_count != 1)
                       cur_mwr_dw_count_wire      = mwr_len_i;
                       state_rq_wire[SEND_WHDR]   = 1'b1;
                    end
                 end
              end else begin // ~s_axis_rq_tready
                 state_rq_wire[SEND_DATA]   = 1'b1;
              end
           end   // SEND_DATA

           state_rq[SEND_DFLH]: begin
              if (s_axis_rq_tready) begin
                 s_axis_rq_tvalid_wire   = 1'b1;
                 s_axis_rq_tdata_wire    = 'd0;
                 s_axis_rq_tuser_wire    = {AXI4_RQ_TUSER_WIDTH{1'b0}};
                 s_axis_rq_tlast_wire    = 1'b0;
                 s_axis_rq_tkeep_wire    = 'd0;

                 seq_num_assigned_0                     = 1'b1;
                 seq_num_assigned_1                     = 1'b0;
                 s_axis_rq_tuser_wire.seq_num0          = SEQ_NUM_IGNORE ? 6'h00 : curr_seq_num;
                 s_axis_rq_tuser_wire.seq_num1          = 6'h00;  
                 s_axis_rq_tdata_wire.ud                = {4{mwr_data_i}};
                 s_axis_rq_tdata_wire.uh.req_type       = 4'b0001;
                 s_axis_rq_tdata_wire.uh.dword_count    = mwr_len_i;
                 s_axis_rq_tdata_wire.uh.addr_63_2      = {32'd0, wr_addr_31_2_2nd};
                 s_axis_rq_tdata_wire[255:0]            = {8{mwr_data_i}} & ({8{32'hFFFFFFFF}} >> ((8 - cur_mwr_dw_count) * 32));
                 s_axis_rq_tuser_wire.last_be           = 8'h0F;
                 s_axis_rq_tuser_wire.first_be          = 8'h0F;
                 s_axis_rq_tuser_wire.is_sop            = 2'b01;
                 s_axis_rq_tuser_wire.is_eop            = 2'b01;
                 s_axis_rq_tuser_wire.is_sop0_ptr       = 2'b10;
                 s_axis_rq_tuser_wire.is_eop0_ptr       = cur_mwr_dw_count[3:0] - 1;

                 // Update flags
                 total_mwr_count_wire       = total_mwr_count - 1;
                 w_tcnt_wire                = w_tcnt + 1;

                 cur_mwr_dw_count_wire      = mwr_len_i - 4;
                 state_rq_wire[SEND_DATA]   = 1'b1;
              end else begin // ~s_axis_rq_tready
                 state_rq_wire[SEND_DFLH]   = 1'b1;
              end
           end   // SEND_DFLH

           state_rq[SEND_WSTD]: begin // Two Writes, only valid when straddle is enabled
              if (~s_axis_rq_tvalid | s_axis_rq_tready) begin
                 s_axis_rq_tvalid_wire   = 1'b1;
                 s_axis_rq_tdata_wire    = 'd0;
                 s_axis_rq_tuser_wire    = {AXI4_RQ_TUSER_WIDTH{1'b0}};
                 s_axis_rq_tlast_wire    = 1'b0;
                 s_axis_rq_tkeep_wire    = 'd0;

                 seq_num_assigned_0                     = 1'b1;
                 seq_num_assigned_1                     = 1'b1;
                 s_axis_rq_tuser_wire.seq_num0          = SEQ_NUM_IGNORE ? 6'h00 : curr_seq_num;
                 s_axis_rq_tuser_wire.seq_num1          = SEQ_NUM_IGNORE ? 6'h00 : (&curr_seq_num) ? 6'h1 : (curr_seq_num + 1'b1);
                 s_axis_rq_tdata_wire.ud                = {4{mwr_data_i}} & ({4{32'hFFFFFFFF}} >> ((4 - cur_mwr_dw_count) * 32));
                 s_axis_rq_tdata_wire.uh.req_type       = 4'b0001;
                 s_axis_rq_tdata_wire.uh.dword_count    = mwr_len_i;
                 s_axis_rq_tdata_wire.uh.addr_63_2      = {32'd0, wr_addr_31_2_2nd};
                 s_axis_rq_tdata_wire.ld                = {4{mwr_data_i}} & ({4{32'hFFFFFFFF}} >> ((4 - cur_mwr_dw_count) * 32));
                 s_axis_rq_tdata_wire.lh.req_type       = 4'b0001;
                 s_axis_rq_tdata_wire.lh.dword_count    = mwr_len_i;
                 s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, wr_addr_31_2};
                 s_axis_rq_tuser_wire.last_be           = (mwr_len_i == 1)? 8'h00: 8'hFF;
                 s_axis_rq_tuser_wire.first_be          = 8'hFF;
                 s_axis_rq_tuser_wire.is_sop            = 2'b11;
                 s_axis_rq_tuser_wire.is_eop            = 2'b11;
                 s_axis_rq_tuser_wire.is_sop0_ptr       = 2'b00;
                 s_axis_rq_tuser_wire.is_sop1_ptr       = 2'b10;               
                 s_axis_rq_tuser_wire.is_eop0_ptr       = mwr_len_i[3:0] + 3;
                 s_axis_rq_tuser_wire.is_eop1_ptr       = mwr_len_i[3:0] + 11;

                 // Update flags
                 total_mwr_count_wire       = total_mwr_count - 2;
                 w_tcnt_wire                = w_tcnt + 2;

                 if (total_mwr_count == 3) begin  // One write left after this state
                    state_rq_wire[SEND_WHDR]   = 1'b1;
                 end else if (total_mwr_count == 2) begin  // All writes are done
                    state_rq_wire[LAST]        = 1'b1;
                 end else begin // (total_mwr_count != 2 or 3)
                    state_rq_wire[SEND_WSTD]   = 1'b1;
                 end
              end else begin // ~s_axis_rq_tready
                 state_rq_wire[SEND_WSTD]   = 1'b1;
              end
           end   // SEND_WSTD

           state_rq[LAST]: begin
              if (s_axis_rq_tready) begin
                 s_axis_rq_tvalid_wire   = 1'b0;
                 mwr_done_wire           = 1'b1;
                 state_rq_wire[IDLE]     = 1'b1;
              end else begin // (~s_axis_rq_tready)
                 state_rq_wire[LAST]     = 1'b1;
              end
           end   // LAST
        endcase
     end
   end
   else // generate if(AXISTEN_IF_REQ_ALIGNMENT_MODE == "TRUE")
   begin

     always_comb begin
        total_mwr_count_wire    = total_mwr_count;
        cur_mwr_dw_count_wire   = cur_mwr_dw_count;
        w_tcnt_wire             = w_tcnt;
        s_axis_rq_tdata_wire    = s_axis_rq_tdata_reg;
        s_axis_rq_tkeep_wire    = s_axis_rq_tkeep;
        s_axis_rq_tlast_wire    = s_axis_rq_tlast;
        s_axis_rq_tvalid_wire   = s_axis_rq_tvalid;
        s_axis_rq_tuser_wire    = s_axis_rq_tuser_reg;
        mwr_done_wire           = mwr_done_o;
        state_rq_wire           = 'd0;
        seq_num_assigned_0      = 1'b0;
        seq_num_assigned_1      = 1'b0;

        case (1'b1)
           state_rq[IDLE]: begin
              w_tcnt_wire = 'd0;
              if (mwr_start_i & (mwr_count_i[15:0] != 0) & ~mwr_done_o) begin
                 // Latch all the commands
                 total_mwr_count_wire    = mwr_count_i;
                 cur_mwr_dw_count_wire   = mwr_len_i;
                 if (AXISTEN_IF_RQ_STRADDLE) begin
                    if (mwr_count_i == 1) begin
                          state_rq_wire[SEND_WHDR]   = 1'b1;
                    end else begin // (mwr_count_i != 1)
                       if (mwr_len_i > 4) begin
                          state_rq_wire[SEND_WHDR]   = 1'b1;
                       end else begin // (mwr_len_i <= 4)
                          state_rq_wire[SEND_WSTD]   = 1'b1;
                       end
                    end
                 end else begin // !AXISTEN_IF_RQ_STRADDLE
                    state_rq_wire[SEND_WHDR]   = 1'b1;
                 end
              end else begin // no requests
                 state_rq_wire[IDLE]  = 1'b1;
              end
           end   // IDLE

           state_rq[SEND_WHDR]: begin // One Write
              if (~s_axis_rq_tvalid | s_axis_rq_tready) begin
                 s_axis_rq_tvalid_wire   = 1'b1;
                 s_axis_rq_tdata_wire    = 'd0;
                 s_axis_rq_tuser_wire    = {AXI4_RQ_TUSER_WIDTH{1'b0}};
                 s_axis_rq_tlast_wire    = 1'b0;
                 s_axis_rq_tkeep_wire    = 'd0;

                 seq_num_assigned_0                        = 1'b1;
                 seq_num_assigned_1                        = 1'b0;
                 s_axis_rq_tuser_wire.seq_num0             = SEQ_NUM_IGNORE ? 6'h00 : curr_seq_num;
                 s_axis_rq_tuser_wire.seq_num1             = 6'h00;

                 case(wr_addr_31_2[1:0])
                   2'b00: begin
                     if (cur_mwr_dw_count > 12) begin
                        s_axis_rq_tdata_wire[511:128]          = {12{mwr_data_i}};
                        s_axis_rq_tdata_wire.lh.req_type       = 4'b0001;
                        s_axis_rq_tdata_wire.lh.dword_count    = mwr_len_i;
                        s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, wr_addr_31_2};
                        s_axis_rq_tuser_wire.last_be           = 8'h0F;
                        s_axis_rq_tuser_wire.first_be          = 8'h0F;
                        s_axis_rq_tuser_wire.addr_offset       = 4'h0;
                        s_axis_rq_tkeep_wire                = 16'hFFFF;

                        cur_mwr_dw_count_wire      = cur_mwr_dw_count - 12;
                        state_rq_wire[SEND_DATA]   = 1'b1;  
                     end else begin // (cur_mwr_dw_count <= 12)
                        s_axis_rq_tdata_wire[511:128]          = {12{mwr_data_i}} & ({12{32'hFFFFFFFF}} >> ((12 - cur_mwr_dw_count) * 32));
                        s_axis_rq_tdata_wire.lh.req_type       = 4'b0001;
                        s_axis_rq_tdata_wire.lh.dword_count    = mwr_len_i;
                        s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, wr_addr_31_2};
                        s_axis_rq_tuser_wire.last_be           = (mwr_len_i == 1)? 8'h00: 8'h0F;
                        s_axis_rq_tuser_wire.first_be          = 8'h0F;
                        s_axis_rq_tuser_wire.addr_offset       = 4'h0;
                        s_axis_rq_tlast_wire                   = 1'b1;
                        s_axis_rq_tkeep_wire                   = 16'hFFFF >> (12 - cur_mwr_dw_count);
                        // Update flags
                        total_mwr_count_wire       = total_mwr_count - 1;
                        w_tcnt_wire                = w_tcnt + 1;
                        if (total_mwr_count == 1) begin  // All writes are done
                           state_rq_wire[LAST]        = 1'b1;
                        end else begin // (total_mwr_count != 1)
                           cur_mwr_dw_count_wire      = mwr_len_i;
                           state_rq_wire[SEND_WHDR]   = 1'b1;
                        end
                     end
                   end

                   2'b01: begin
                     if (cur_mwr_dw_count > 11) begin
                        s_axis_rq_tdata_wire[511:128]          ={{11{mwr_data_i}},32'b0};
                        s_axis_rq_tdata_wire.lh.req_type       = 4'b0001;
                        s_axis_rq_tdata_wire.lh.dword_count    = mwr_len_i;
                        s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, wr_addr_31_2};
                        s_axis_rq_tuser_wire.last_be           = 8'h0F;
                        s_axis_rq_tuser_wire.first_be          = 8'h0F;
                        s_axis_rq_tuser_wire.addr_offset       = 4'h1;
                        s_axis_rq_tkeep_wire                   = 16'hFFFF;

                        cur_mwr_dw_count_wire      = cur_mwr_dw_count - 11;
                        state_rq_wire[SEND_DATA]   = 1'b1;  
                     end else begin // (cur_mwr_dw_count <= 12)
                        s_axis_rq_tdata_wire[511:128]          = {{{11{mwr_data_i}} & ({11{32'hFFFFFFFF}} >> ((11 - cur_mwr_dw_count) * 32))}, 32'b0};
                        s_axis_rq_tdata_wire.lh.req_type       = 4'b0001;
                        s_axis_rq_tdata_wire.lh.dword_count    = mwr_len_i;
                        s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, wr_addr_31_2};
                        s_axis_rq_tuser_wire.last_be           = (mwr_len_i == 1)? 8'h00: 8'h0F;
                        s_axis_rq_tuser_wire.first_be          = 8'h0F;
                        s_axis_rq_tuser_wire.addr_offset       = 4'h1;
                        s_axis_rq_tlast_wire                   = 1'b1;
                        s_axis_rq_tkeep_wire                   = 16'hFFFF >> (11 - cur_mwr_dw_count);
                        // Update flags
                        total_mwr_count_wire       = total_mwr_count - 1;
                        w_tcnt_wire                = w_tcnt + 1;
                        if (total_mwr_count == 1) begin  // All writes are done
                           state_rq_wire[LAST]        = 1'b1;
                        end else begin // (total_mwr_count != 1)
                           cur_mwr_dw_count_wire      = mwr_len_i;
                           state_rq_wire[SEND_WHDR]   = 1'b1;
                        end
                     end
                   end
                   2'b10: begin
                     if (cur_mwr_dw_count > 10) begin
                        s_axis_rq_tdata_wire[511:128]          ={{10{mwr_data_i}},64'b0};
                        s_axis_rq_tdata_wire.lh.req_type       = 4'b0001;
                        s_axis_rq_tdata_wire.lh.dword_count    = mwr_len_i;
                        s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, wr_addr_31_2};
                        s_axis_rq_tuser_wire.last_be           = 8'h0F;
                        s_axis_rq_tuser_wire.first_be          = 8'h0F;
                        s_axis_rq_tuser_wire.addr_offset       = 4'h2;
                        s_axis_rq_tkeep_wire                   = 16'hFFFF;

                        cur_mwr_dw_count_wire      = cur_mwr_dw_count - 10;
                        state_rq_wire[SEND_DATA]   = 1'b1;  
                     end else begin // (cur_mwr_dw_count <= 12)
                        s_axis_rq_tdata_wire[511:128]          = {{{10{mwr_data_i}} & ({10{32'hFFFFFFFF}} >> ((10 - cur_mwr_dw_count) * 32))}, 64'b0};
                        s_axis_rq_tdata_wire.lh.req_type       = 4'b0001;
                        s_axis_rq_tdata_wire.lh.dword_count    = mwr_len_i;
                        s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, wr_addr_31_2};
                        s_axis_rq_tuser_wire.last_be           = (mwr_len_i == 1)? 8'h00: 8'h0F;
                        s_axis_rq_tuser_wire.first_be          = 8'h0F;
                        s_axis_rq_tuser_wire.addr_offset       = 4'h2;
                        s_axis_rq_tlast_wire                   = 1'b1;
                        s_axis_rq_tkeep_wire                   = 16'hFFFF >> (10 - cur_mwr_dw_count);
                        // Update flags
                        total_mwr_count_wire       = total_mwr_count - 1;
                        w_tcnt_wire                = w_tcnt + 1;
                        if (total_mwr_count == 1) begin  // All writes are done
                           state_rq_wire[LAST]        = 1'b1;
                        end else begin // (total_mwr_count != 1)
                           cur_mwr_dw_count_wire      = mwr_len_i;
                           state_rq_wire[SEND_WHDR]   = 1'b1;
                        end
                     end
                   end
                   2'b11: begin
                     if (cur_mwr_dw_count > 9) begin
                        s_axis_rq_tdata_wire[511:128]          ={{ 9{mwr_data_i}},96'b0};
                        s_axis_rq_tdata_wire.lh.req_type       = 4'b0001;
                        s_axis_rq_tdata_wire.lh.dword_count    = mwr_len_i;
                        s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, wr_addr_31_2};
                        s_axis_rq_tuser_wire.last_be           = 8'h0F;
                        s_axis_rq_tuser_wire.first_be          = 8'h0F;
                        s_axis_rq_tuser_wire.addr_offset       = 4'h3;
                        s_axis_rq_tkeep_wire                = 16'hFFFF;

                        cur_mwr_dw_count_wire      = cur_mwr_dw_count - 9;
                        state_rq_wire[SEND_DATA]   = 1'b1;  
                     end else begin // (cur_mwr_dw_count <= 12)
                        s_axis_rq_tdata_wire[511:128]          = {{{9{mwr_data_i}} & ({9{32'hFFFFFFFF}} >> ((9 - cur_mwr_dw_count) * 32))},96'b0};
                        s_axis_rq_tdata_wire.lh.req_type       = 4'b0001;
                        s_axis_rq_tdata_wire.lh.dword_count    = mwr_len_i;
                        s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, wr_addr_31_2};
                        s_axis_rq_tuser_wire.last_be           = (mwr_len_i == 1)? 8'h00: 8'h0F;
                        s_axis_rq_tuser_wire.first_be          = 8'h0F;
                        s_axis_rq_tuser_wire.addr_offset       = 4'h3;
                        s_axis_rq_tlast_wire                   = 1'b1;
                        s_axis_rq_tkeep_wire                   = 16'hFFFF >> (9 - cur_mwr_dw_count);
                        // Update flags
                        total_mwr_count_wire       = total_mwr_count - 1;
                        w_tcnt_wire                = w_tcnt + 1;
                        if (total_mwr_count == 1) begin  // All writes are done
                           state_rq_wire[LAST]        = 1'b1;
                        end else begin // (total_mwr_count != 1)
                           cur_mwr_dw_count_wire      = mwr_len_i;
                           state_rq_wire[SEND_WHDR]   = 1'b1;
                        end
                     end
                   end


                 endcase
              end else begin // ~s_axis_rq_tready
                 state_rq_wire[SEND_WHDR]   = 1'b1;
              end
           end   // SEND_WHDR

           state_rq[SEND_DATA]: begin
              if (s_axis_rq_tready) begin
                 s_axis_rq_tvalid_wire   = 1'b1;
                 s_axis_rq_tdata_wire    = 'd0;
                 s_axis_rq_tuser_wire    = {AXI4_RQ_TUSER_WIDTH{1'b0}};
                 s_axis_rq_tlast_wire    = 1'b0;
                 s_axis_rq_tkeep_wire    = 'd0;

                 if (cur_mwr_dw_count > 16) begin
                    s_axis_rq_tdata_wire                   = {16{mwr_data_i}};
                    if (~AXISTEN_IF_RQ_STRADDLE) begin
                       s_axis_rq_tkeep_wire                = 16'hFFFF;
                    end

                    cur_mwr_dw_count_wire      = cur_mwr_dw_count - 16;
                    state_rq_wire[SEND_DATA]   = 1'b1;
                 end else begin // (cur_mwr_dw_count <= 16)
                    s_axis_rq_tdata_wire                   = {16{mwr_data_i}} & ({16{32'hFFFFFFFF}} >> ((16 - cur_mwr_dw_count) * 32));
                    if (AXISTEN_IF_RQ_STRADDLE) begin
                       s_axis_rq_tuser_wire.is_eop         = 2'b01;
                       s_axis_rq_tuser_wire.is_eop0_ptr    = cur_mwr_dw_count[3:0] - 1;
                    end else begin
                       s_axis_rq_tlast_wire                = 1'b1;
                       s_axis_rq_tkeep_wire                = 16'hFFFF >> (16 - cur_mwr_dw_count);
                    end

                    // Update flags
                    total_mwr_count_wire       = total_mwr_count - 1;
                    w_tcnt_wire                = w_tcnt + 1;
                    
                    if (total_mwr_count == 1) begin  // All writes are done
                       state_rq_wire[LAST]        = 1'b1;
                    end else begin // (total_mwr_count != 1)
                       cur_mwr_dw_count_wire      = mwr_len_i;
                       state_rq_wire[SEND_WHDR]   = 1'b1;
                    end
                 end
              end else begin // ~s_axis_rq_tready
                 state_rq_wire[SEND_DATA]   = 1'b1;
              end
           end   // SEND_DATA

           state_rq[SEND_DFLH]: begin
              if (s_axis_rq_tready) begin
                 s_axis_rq_tvalid_wire   = 1'b1;
                 s_axis_rq_tdata_wire    = 'd0;
                 s_axis_rq_tuser_wire    = {AXI4_RQ_TUSER_WIDTH{1'b0}};
                 s_axis_rq_tlast_wire    = 1'b0;
                 s_axis_rq_tkeep_wire    = 'd0;

                 seq_num_assigned_0                     = 1'b1;
                 seq_num_assigned_1                     = 1'b0;
                 s_axis_rq_tuser_wire.seq_num0          = SEQ_NUM_IGNORE ? 6'h00 : curr_seq_num;
                 s_axis_rq_tuser_wire.seq_num1          = 6'h00;  
                 s_axis_rq_tdata_wire.ud                = {4{mwr_data_i}};
                 s_axis_rq_tdata_wire.uh.req_type       = 4'b0001;
                 s_axis_rq_tdata_wire.uh.dword_count    = mwr_len_i;
                 s_axis_rq_tdata_wire.uh.addr_63_2      = {32'd0, wr_addr_31_2_2nd};
                 s_axis_rq_tdata_wire[255:0]            = {8{mwr_data_i}} & ({8{32'hFFFFFFFF}} >> ((8 - cur_mwr_dw_count) * 32));
                 s_axis_rq_tuser_wire.last_be           = 8'h0F;
                 s_axis_rq_tuser_wire.first_be          = 8'h0F;
                 s_axis_rq_tuser_wire.is_sop            = 2'b01;
                 s_axis_rq_tuser_wire.is_eop            = 2'b01;
                 s_axis_rq_tuser_wire.is_sop0_ptr       = 2'b10;
                 s_axis_rq_tuser_wire.is_eop0_ptr       = cur_mwr_dw_count[3:0] - 1;

                 // Update flags
                 total_mwr_count_wire       = total_mwr_count - 1;
                 w_tcnt_wire                = w_tcnt + 1;

                 cur_mwr_dw_count_wire      = mwr_len_i - 4;
                 state_rq_wire[SEND_DATA]   = 1'b1;
              end else begin // ~s_axis_rq_tready
                 state_rq_wire[SEND_DFLH]   = 1'b1;
              end
           end   // SEND_DFLH

           state_rq[SEND_WSTD]: begin // Two Writes, only valid when straddle is enabled
              if (~s_axis_rq_tvalid | s_axis_rq_tready) begin
                 s_axis_rq_tvalid_wire   = 1'b1;
                 s_axis_rq_tdata_wire    = 'd0;
                 s_axis_rq_tuser_wire    = {AXI4_RQ_TUSER_WIDTH{1'b0}};
                 s_axis_rq_tlast_wire    = 1'b0;
                 s_axis_rq_tkeep_wire    = 'd0;

                 seq_num_assigned_0                     = 1'b1;
                 seq_num_assigned_1                     = 1'b1;
                 s_axis_rq_tuser_wire.seq_num0          = SEQ_NUM_IGNORE ? 6'h00 : curr_seq_num;
                 s_axis_rq_tuser_wire.seq_num1          = SEQ_NUM_IGNORE ? 6'h00 : (&curr_seq_num) ? 6'h1 : (curr_seq_num + 1'b1);
                 s_axis_rq_tdata_wire.ud                = {4{mwr_data_i}} & ({4{32'hFFFFFFFF}} >> ((4 - cur_mwr_dw_count) * 32));
                 s_axis_rq_tdata_wire.uh.req_type       = 4'b0001;
                 s_axis_rq_tdata_wire.uh.dword_count    = mwr_len_i;
                 s_axis_rq_tdata_wire.uh.addr_63_2      = {32'd0, wr_addr_31_2_2nd};
                 s_axis_rq_tdata_wire.ld                = {4{mwr_data_i}} & ({4{32'hFFFFFFFF}} >> ((4 - cur_mwr_dw_count) * 32));
                 s_axis_rq_tdata_wire.lh.req_type       = 4'b0001;
                 s_axis_rq_tdata_wire.lh.dword_count    = mwr_len_i;
                 s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, wr_addr_31_2};
                 s_axis_rq_tuser_wire.last_be           = (mwr_len_i == 1)? 8'h00: 8'hFF;
                 s_axis_rq_tuser_wire.first_be          = 8'hFF;
                 s_axis_rq_tuser_wire.is_sop            = 2'b11;
                 s_axis_rq_tuser_wire.is_eop            = 2'b11;
                 s_axis_rq_tuser_wire.is_sop0_ptr       = 2'b00;
                 s_axis_rq_tuser_wire.is_sop1_ptr       = 2'b10;               
                 s_axis_rq_tuser_wire.is_eop0_ptr       = mwr_len_i[3:0] + 3;
                 s_axis_rq_tuser_wire.is_eop1_ptr       = mwr_len_i[3:0] + 11;

                 // Update flags
                 total_mwr_count_wire       = total_mwr_count - 2;
                 w_tcnt_wire                = w_tcnt + 2;

                 if (total_mwr_count == 3) begin  // One write left after this state
                    state_rq_wire[SEND_WHDR]   = 1'b1;
                 end else if (total_mwr_count == 2) begin  // All writes are done
                    state_rq_wire[LAST]        = 1'b1;
                 end else begin // (total_mwr_count != 2 or 3)
                    state_rq_wire[SEND_WSTD]   = 1'b1;
                 end
              end else begin // ~s_axis_rq_tready
                 state_rq_wire[SEND_WSTD]   = 1'b1;
              end
           end   // SEND_WSTD

           state_rq[LAST]: begin
              if (s_axis_rq_tready) begin
                 s_axis_rq_tvalid_wire   = 1'b0;
                 mwr_done_wire           = 1'b1;
                 state_rq_wire[IDLE]     = 1'b1;
              end else begin // (~s_axis_rq_tready)
                 state_rq_wire[LAST]     = 1'b1;
              end
           end   // LAST
        endcase
     end



   end
   endgenerate

   // Generate parity for data
genvar var_i;
generate
   for (var_i = 0; var_i < 64; var_i = var_i + 1) begin: rq_parity_generation
      assign s_axis_rq_parity[var_i] =  ~(^s_axis_rq_tdata_wire[8*(var_i+1)-1:8*var_i]);
   end
endgenerate

   always_comb begin
      s_axis_rq_tuser_w_parity         = s_axis_rq_tuser_wire;
      s_axis_rq_tuser_w_parity.parity  = AXISTEN_IF_REQ_PARITY_CHECK? s_axis_rq_parity: 64'd0;
   end

   `BMDREG(user_clk, (reset_n & ~init_rst_i), total_mwr_count, total_mwr_count_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), cur_mwr_dw_count, cur_mwr_dw_count_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), w_tcnt, w_tcnt_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tdata_reg, s_axis_rq_tdata_wire, 512'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tkeep, s_axis_rq_tkeep_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tlast, s_axis_rq_tlast_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tvalid, s_axis_rq_tvalid_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tuser_reg, s_axis_rq_tuser_w_parity, 183'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), mwr_done_o, mwr_done_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), state_rq, state_rq_wire, 'd1)

   assign s_axis_rq_tdata  = s_axis_rq_tdata_reg;
   assign s_axis_rq_tuser  = s_axis_rq_tuser_reg;

endmodule // BMD_AXIST_RQ_WRITE_512
