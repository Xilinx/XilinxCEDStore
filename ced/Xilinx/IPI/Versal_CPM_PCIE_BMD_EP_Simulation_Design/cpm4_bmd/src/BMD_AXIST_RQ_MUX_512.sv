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
// Project    : Everest FPGA PCI Express Integrated Block
// File       : BMD_AXIST_RQ_MUX_512.sv
// Version    : 1.0 
//-----------------------------------------------------------------------------

`include "pcie_app_versal_bmd.vh"
`timescale 1ps / 1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_RQ_MUX_512 #(
   parameter         AXISTEN_IF_REQ_ALIGNMENT_MODE = 0,
   parameter         AXISTEN_IF_RQ_STRADDLE        = 0,
   parameter         AXI4_CQ_TUSER_WIDTH           = 183,
   parameter         AXI4_CC_TUSER_WIDTH           = 81,
   parameter         AXI4_RQ_TUSER_WIDTH           = 137,
   parameter         AXI4_RC_TUSER_WIDTH           = 161,
   parameter         TCQ                           = 1
)(
   // Clock and Reset
   input                            user_clk,
   input                            reset_n,
   input                            init_rst_i,

   // BMD Configuration
   input        [7:0]               mwr_wrr_cnt_i, // only support 2, 4, 6...
   input        [7:0]               mrd_wrr_cnt_i, // only support 2, 4, 6...
   input        [3:0]               wait_trn_time_i,

   // AXI-S Requester Request Interface
   input  logic [511:0]             s_axis_rq_tdata_w,
   input        [15:0]              s_axis_rq_tkeep_w,
   input                            s_axis_rq_tlast_w,
   input                            s_axis_rq_tvalid_w,
   input  logic [136:0]             s_axis_rq_tuser_w,
   output logic                     s_axis_rq_tready_w,

   // AXI-S Requester Request Interface
   input  logic [511:0]             s_axis_rq_tdata_r,
   input        [15:0]              s_axis_rq_tkeep_r,
   input                            s_axis_rq_tlast_r,
   input                            s_axis_rq_tvalid_r,
   input  logic [136:0]             s_axis_rq_tuser_r,
   output logic                     s_axis_rq_tready_r,

   // AXI-S Requester Request Interface
   output logic [511:0]             s_axis_rq_tdata_o,
   output logic [15:0]              s_axis_rq_tkeep_o,
   output logic                     s_axis_rq_tlast_o,
   output logic                     s_axis_rq_tvalid_o,
   output logic [136:0]             s_axis_rq_tuser_o,
   input                            s_axis_rq_tready_i
);
   `STRUCT_AXI_RQ_IF

   s_axis_rq_tdata_512  s_axis_rq_tdata_wire;
   s_axis_rq_tdata_512  s_axis_rq_tdata_reg;
   logic [15:0]   s_axis_rq_tkeep_wire;
   logic          s_axis_rq_tlast_wire;
   logic          s_axis_rq_tvalid_wire;
   s_axis_rq_tuser_512  s_axis_rq_tuser_wire;
   s_axis_rq_tuser_512  s_axis_rq_tuser_w_s;
   s_axis_rq_tuser_512  s_axis_rq_tuser_reg;
   logic [3:0]    wait_trn_time, wait_trn_time_wire;
   logic [7:0]    burst_wr_count, burst_wr_count_wire;
   logic [7:0]    burst_rd_count, burst_rd_count_wire;
   logic          data_in_prog, data_in_prog_wire;

   assign s_axis_rq_tuser_w_s = s_axis_rq_tuser_w;

   localparam  W_1ST       = 0;
   localparam  W_CTN       = 1;
   localparam  R_1ST       = 2;
   localparam  R_CTN       = 3;

   localparam  STATE_CNT   = 4;

   logic [STATE_CNT-1:0]   state_mx, state_mx_wire;

   always_comb begin
      s_axis_rq_tdata_wire    = s_axis_rq_tdata_reg;
      s_axis_rq_tkeep_wire    = s_axis_rq_tkeep_o;
      s_axis_rq_tlast_wire    = s_axis_rq_tlast_o;
      s_axis_rq_tvalid_wire   = s_axis_rq_tvalid_o;
      s_axis_rq_tuser_wire    = s_axis_rq_tuser_reg;
      wait_trn_time_wire      = wait_trn_time;
      burst_wr_count_wire     = burst_wr_count;
      burst_rd_count_wire     = burst_rd_count;
      data_in_prog_wire       = data_in_prog;
      state_mx_wire           = 'd0;

      case (1'b1)
         state_mx[W_1ST]: begin
            if (wait_trn_time == 0) begin
               if (~s_axis_rq_tvalid_o | s_axis_rq_tready_i) begin
                  if (s_axis_rq_tvalid_w) begin
                     s_axis_rq_tdata_wire    = s_axis_rq_tdata_w;
                     s_axis_rq_tkeep_wire    = s_axis_rq_tkeep_w;
                     s_axis_rq_tlast_wire    = s_axis_rq_tlast_w;
                     s_axis_rq_tvalid_wire   = s_axis_rq_tvalid_w;
                     s_axis_rq_tuser_wire    = s_axis_rq_tuser_w_s;                      
                     wait_trn_time_wire      = wait_trn_time_i;

                     if (AXISTEN_IF_RQ_STRADDLE) begin
                        if ((s_axis_rq_tuser_w_s.is_eop == 2'b11) & (mwr_wrr_cnt_i == 2)) begin
                           state_mx_wire[R_1ST] = 1'b1;
                        end else begin // Write is not done
                           if (s_axis_rq_tuser_w_s.is_eop == 2'b11) begin
                              burst_wr_count_wire  = mwr_wrr_cnt_i - 2;
                           end else if (s_axis_rq_tuser_w_s.is_eop == 2'b01) begin
                              burst_wr_count_wire  = mwr_wrr_cnt_i - 1;
                           end else begin // no eop
                              data_in_prog_wire    = 1'b1;
                              burst_wr_count_wire  = mwr_wrr_cnt_i;
                           end
                           state_mx_wire[W_CTN] = 1'b1;
                        end
                     end else begin // ~AXISTEN_IF_RQ_STRADDLE
                        if (s_axis_rq_tlast_w) begin
                           burst_wr_count_wire  = mwr_wrr_cnt_i - 1;
                        end else begin // no last
                           data_in_prog_wire    = 1'b1;
                           burst_wr_count_wire  = mwr_wrr_cnt_i;
                        end
                        state_mx_wire[W_CTN] = 1'b1;
                     end
                  end else if (s_axis_rq_tvalid_r) begin
                     s_axis_rq_tdata_wire    = s_axis_rq_tdata_r;
                     s_axis_rq_tkeep_wire    = s_axis_rq_tkeep_r;
                     s_axis_rq_tlast_wire    = s_axis_rq_tlast_r;
                     s_axis_rq_tvalid_wire   = s_axis_rq_tvalid_r;
                     s_axis_rq_tuser_wire    = s_axis_rq_tuser_r;
                     wait_trn_time_wire      = wait_trn_time_i;

                     if (AXISTEN_IF_RQ_STRADDLE) begin
                        if (mrd_wrr_cnt_i == 2) begin
                           state_mx_wire[W_1ST] = 1'b1;
                        end else begin // Read is not done
                           burst_rd_count_wire  = mrd_wrr_cnt_i - 2;
                           state_mx_wire[R_CTN] = 1'b1;
                        end
                     end else begin // ~AXISTEN_IF_RQ_STRADDLE
                        burst_rd_count_wire  = mrd_wrr_cnt_i - 1;
                        state_mx_wire[R_CTN] = 1'b1;
                     end
                  end else begin // no Writes and Reads
                     s_axis_rq_tvalid_wire   = 1'b0;

                     state_mx_wire[W_1ST] = 1'b1;
                  end
               end else begin // ~(~s_axis_rq_tvalid_o | s_axis_rq_tready_i)
                  state_mx_wire[W_1ST] = 1'b1;
               end
            end else begin // (wait_trn_time != 0)
               wait_trn_time_wire   = wait_trn_time - 1;
               if (s_axis_rq_tready_i) begin
                  s_axis_rq_tvalid_wire   = 1'b0;
               end
               state_mx_wire[W_1ST] = 1'b1;
            end
         end   // W_1ST

         state_mx[W_CTN]: begin
            if ((wait_trn_time == 0) | data_in_prog) begin
               if (s_axis_rq_tready_i) begin
                  if (s_axis_rq_tvalid_w) begin
                     s_axis_rq_tdata_wire    = s_axis_rq_tdata_w;
                     s_axis_rq_tkeep_wire    = s_axis_rq_tkeep_w;
                     s_axis_rq_tlast_wire    = s_axis_rq_tlast_w;
                     s_axis_rq_tvalid_wire   = s_axis_rq_tvalid_w;
                     s_axis_rq_tuser_wire    = s_axis_rq_tuser_w_s;                      
                     wait_trn_time_wire      = wait_trn_time_i;
                     data_in_prog_wire       = 1'b0;

                     if (AXISTEN_IF_RQ_STRADDLE) begin
                        if (((s_axis_rq_tuser_w_s.is_eop == 2'b11) & (burst_wr_count == 2)) | 
                            ((s_axis_rq_tuser_w_s.is_eop == 2'b01) & (burst_wr_count == 1))) begin
                           state_mx_wire[R_1ST] = 1'b1;
                        end else begin // Write is not done
                           if (s_axis_rq_tuser_w_s.is_eop == 2'b11) begin
                              burst_wr_count_wire  = burst_wr_count - 2;
                           end else if (s_axis_rq_tuser_w_s.is_eop == 2'b01) begin
                              if (~s_axis_rq_tuser_w_s.is_eop0_ptr[3] & (s_axis_rq_tuser_w_s.is_sop == 2'b01)) begin
                                 data_in_prog_wire    = 1'b1;
                              end
                              burst_wr_count_wire  = burst_wr_count - 1;
                           end else begin // no eop
                              data_in_prog_wire    = 1'b1;
                           end
                           state_mx_wire[W_CTN] = 1'b1;
                        end
                     end else begin // ~AXISTEN_IF_RQ_STRADDLE
                        if (s_axis_rq_tlast_w & (burst_wr_count == 1)) begin
                           state_mx_wire[R_1ST] = 1'b1;
                        end else begin // Write is not done
                           if (s_axis_rq_tlast_w) begin
                              burst_wr_count_wire  = burst_wr_count - 1;
                           end else begin // no last
                              data_in_prog_wire    = 1'b1;
                           end
                           state_mx_wire[W_CTN] = 1'b1;
                        end
                     end
                  end else if (s_axis_rq_tvalid_r) begin
                     s_axis_rq_tdata_wire    = s_axis_rq_tdata_r;
                     s_axis_rq_tkeep_wire    = s_axis_rq_tkeep_r;
                     s_axis_rq_tlast_wire    = s_axis_rq_tlast_r;
                     s_axis_rq_tvalid_wire   = s_axis_rq_tvalid_r;
                     s_axis_rq_tuser_wire    = s_axis_rq_tuser_r;
                     wait_trn_time_wire      = wait_trn_time_i;
                     data_in_prog_wire       = 1'b0;

                     if (AXISTEN_IF_RQ_STRADDLE) begin
                        if (mrd_wrr_cnt_i == 2) begin
                           state_mx_wire[W_1ST] = 1'b1;
                        end else begin // Read is not done
                           burst_rd_count_wire  = mrd_wrr_cnt_i - 2;
                           state_mx_wire[R_CTN] = 1'b1;
                        end
                     end else begin // ~AXISTEN_IF_RQ_STRADDLE
                        burst_rd_count_wire  = mrd_wrr_cnt_i - 1;
                        state_mx_wire[R_CTN] = 1'b1;
                     end
                  end else begin // no Writes and Reads
                     s_axis_rq_tvalid_wire   = 1'b0;
                     data_in_prog_wire       = 1'b0;

                     state_mx_wire[R_1ST] = 1'b1;
                  end
               end else begin // ~(~s_axis_rq_tvalid_o | s_axis_rq_tready_i)
                  state_mx_wire[W_CTN] = 1'b1;
               end
            end else begin // (wait_trn_time != 0)
               wait_trn_time_wire   = wait_trn_time - 1;
               if (s_axis_rq_tready_i) begin
                  s_axis_rq_tvalid_wire   = 1'b0;
               end
               state_mx_wire[W_CTN] = 1'b1;
            end
         end   // W_CTN

         state_mx[R_1ST]: begin
            if (wait_trn_time == 0) begin
               if (~s_axis_rq_tvalid_o | s_axis_rq_tready_i) begin
                  if (s_axis_rq_tvalid_r) begin
                     s_axis_rq_tdata_wire    = s_axis_rq_tdata_r;
                     s_axis_rq_tkeep_wire    = s_axis_rq_tkeep_r;
                     s_axis_rq_tlast_wire    = s_axis_rq_tlast_r;
                     s_axis_rq_tvalid_wire   = s_axis_rq_tvalid_r;
                     s_axis_rq_tuser_wire    = s_axis_rq_tuser_r;
                     wait_trn_time_wire      = wait_trn_time_i;

                     if (AXISTEN_IF_RQ_STRADDLE) begin
                        if (mrd_wrr_cnt_i == 2) begin
                           state_mx_wire[W_1ST] = 1'b1;
                        end else begin // Read is not done
                           burst_rd_count_wire  = mrd_wrr_cnt_i - 2;
                           state_mx_wire[R_CTN] = 1'b1;
                        end
                     end else begin // ~AXISTEN_IF_RQ_STRADDLE
                        burst_rd_count_wire  = mrd_wrr_cnt_i - 1;
                        state_mx_wire[R_CTN] = 1'b1;
                     end
                  end else if (s_axis_rq_tvalid_w) begin
                     s_axis_rq_tdata_wire    = s_axis_rq_tdata_w;
                     s_axis_rq_tkeep_wire    = s_axis_rq_tkeep_w;
                     s_axis_rq_tlast_wire    = s_axis_rq_tlast_w;
                     s_axis_rq_tvalid_wire   = s_axis_rq_tvalid_w;
                     s_axis_rq_tuser_wire    = s_axis_rq_tuser_w_s;                      
                     wait_trn_time_wire      = wait_trn_time_i;

                     if (AXISTEN_IF_RQ_STRADDLE) begin
                        if ((s_axis_rq_tuser_w_s.is_eop == 2'b11) & (mwr_wrr_cnt_i == 2)) begin
                           state_mx_wire[R_1ST] = 1'b1;
                        end else begin // Write is not done
                           if (s_axis_rq_tuser_w_s.is_eop == 2'b11) begin
                              burst_wr_count_wire  = mwr_wrr_cnt_i - 2;
                           end else if (s_axis_rq_tuser_w_s.is_eop == 2'b01) begin
                              burst_wr_count_wire  = mwr_wrr_cnt_i - 1;
                           end else begin // no eop
                              data_in_prog_wire    = 1'b1;
                              burst_wr_count_wire  = mwr_wrr_cnt_i;
                           end
                           state_mx_wire[W_CTN] = 1'b1;
                        end
                     end else begin // ~AXISTEN_IF_RQ_STRADDLE
                        if (s_axis_rq_tlast_w) begin
                           burst_wr_count_wire  = mwr_wrr_cnt_i - 1;
                        end else begin // no last
                           data_in_prog_wire    = 1'b1;
                           burst_wr_count_wire  = mwr_wrr_cnt_i;
                        end
                        state_mx_wire[W_CTN] = 1'b1;
                     end                     
                  end else begin // no Writes and Reads
                     s_axis_rq_tvalid_wire   = 1'b0;

                     state_mx_wire[R_1ST] = 1'b1;
                  end
               end else begin // ~(~s_axis_rq_tvalid_o | s_axis_rq_tready_i)
                  state_mx_wire[R_1ST] = 1'b1;
               end
            end else begin // (wait_trn_time != 0)
               wait_trn_time_wire   = wait_trn_time - 1;
               if (s_axis_rq_tready_i) begin
                  s_axis_rq_tvalid_wire   = 1'b0;
               end
               state_mx_wire[R_1ST] = 1'b1;
            end
         end   // R_1ST

         state_mx[R_CTN]: begin
            if (wait_trn_time == 0) begin
               if (s_axis_rq_tready_i) begin
                  if (s_axis_rq_tvalid_r) begin
                     s_axis_rq_tdata_wire    = s_axis_rq_tdata_r;
                     s_axis_rq_tkeep_wire    = s_axis_rq_tkeep_r;
                     s_axis_rq_tlast_wire    = s_axis_rq_tlast_r;
                     s_axis_rq_tvalid_wire   = s_axis_rq_tvalid_r;
                     s_axis_rq_tuser_wire    = s_axis_rq_tuser_r;
                     wait_trn_time_wire      = wait_trn_time_i;

                     if (AXISTEN_IF_RQ_STRADDLE) begin
                        if (burst_rd_count == 2) begin
                           state_mx_wire[W_1ST] = 1'b1;
                        end else begin // Read is not done
                           burst_rd_count_wire  = burst_rd_count - 2;
                           state_mx_wire[R_CTN] = 1'b1;
                        end
                     end else begin // ~AXISTEN_IF_RQ_STRADDLE
                        burst_rd_count_wire  = burst_rd_count - 1;
                        state_mx_wire[R_CTN] = 1'b1;
                     end
                  end else if (s_axis_rq_tvalid_w) begin
                     s_axis_rq_tdata_wire    = s_axis_rq_tdata_w;
                     s_axis_rq_tkeep_wire    = s_axis_rq_tkeep_w;
                     s_axis_rq_tlast_wire    = s_axis_rq_tlast_w;
                     s_axis_rq_tvalid_wire   = s_axis_rq_tvalid_w;
                     s_axis_rq_tuser_wire    = s_axis_rq_tuser_w_s;                      
                     wait_trn_time_wire      = wait_trn_time_i;

                     if (AXISTEN_IF_RQ_STRADDLE) begin
                        if ((s_axis_rq_tuser_w_s.is_eop == 2'b11) & (mwr_wrr_cnt_i == 2)) begin
                           state_mx_wire[R_1ST] = 1'b1;
                        end else begin // Write is not done
                           if (s_axis_rq_tuser_w_s.is_eop == 2'b11) begin
                              burst_wr_count_wire  = mwr_wrr_cnt_i - 2;
                           end else if (s_axis_rq_tuser_w_s.is_eop == 2'b01) begin
                              burst_wr_count_wire  = mwr_wrr_cnt_i - 1;
                           end else begin // no eop
                              burst_wr_count_wire  = mwr_wrr_cnt_i;
                              data_in_prog_wire    = 1'b1;
                           end
                           state_mx_wire[W_CTN] = 1'b1;
                        end
                     end else begin // ~AXISTEN_IF_RQ_STRADDLE
                        if (s_axis_rq_tlast_w) begin
                           burst_wr_count_wire  = mwr_wrr_cnt_i - 1;
                        end else begin // no last
                           burst_wr_count_wire  = mwr_wrr_cnt_i;
                           data_in_prog_wire    = 1'b1;
                        end
                        state_mx_wire[W_CTN] = 1'b1;
                     end                     
                  end else begin // no Writes and Reads
                     s_axis_rq_tvalid_wire   = 1'b0;

                     state_mx_wire[W_1ST] = 1'b1;
                  end
               end else begin // ~(~s_axis_rq_tvalid_o | s_axis_rq_tready_i)
                  state_mx_wire[R_CTN] = 1'b1;
               end
            end else begin // (wait_trn_time != 0)
               wait_trn_time_wire   = wait_trn_time - 1;
               if (s_axis_rq_tready_i) begin
                  s_axis_rq_tvalid_wire   = 1'b0;
               end
               state_mx_wire[R_CTN] = 1'b1;
            end
         end   // R_CTN
      endcase
   end

   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tdata_reg, s_axis_rq_tdata_wire, 512'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tkeep_o, s_axis_rq_tkeep_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tlast_o, s_axis_rq_tlast_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tvalid_o, s_axis_rq_tvalid_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tuser_reg, s_axis_rq_tuser_wire, 137'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), wait_trn_time, wait_trn_time_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), burst_wr_count, burst_wr_count_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), burst_rd_count, burst_rd_count_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), data_in_prog, data_in_prog_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), state_mx, state_mx_wire, 'd1)

   assign s_axis_rq_tdata_o   = s_axis_rq_tdata_reg;
   assign s_axis_rq_tuser_o   = s_axis_rq_tuser_reg;

   always_comb begin
      s_axis_rq_tready_w   = 1'b0;
      s_axis_rq_tready_r   = 1'b0;

      case (1'b1)
         state_mx[W_1ST]: begin
            if (wait_trn_time == 0) begin
               if (~s_axis_rq_tvalid_o | s_axis_rq_tready_i) begin
                  if (s_axis_rq_tvalid_w) begin
                     s_axis_rq_tready_w   = 1'b1;
                  end else if (s_axis_rq_tvalid_r) begin
                     s_axis_rq_tready_r   = 1'b1;
                  end else begin // no Writes and Reads
                     s_axis_rq_tready_w   = 1'b1;
                  end
               end
            end
         end

         state_mx[W_CTN]: begin
            if ((wait_trn_time == 0) | data_in_prog) begin
               if (s_axis_rq_tready_i) begin
                  if (s_axis_rq_tvalid_w) begin
                     s_axis_rq_tready_w   = 1'b1;
                  end else if (s_axis_rq_tvalid_r) begin
                     s_axis_rq_tready_r   = 1'b1;
                  end else begin // no Writes and Reads
                     s_axis_rq_tready_w   = 1'b1;
                  end
               end
            end
         end

         state_mx[R_1ST]: begin
            if (wait_trn_time == 0) begin
               if (~s_axis_rq_tvalid_o | s_axis_rq_tready_i) begin
                  if (s_axis_rq_tvalid_r) begin
                     s_axis_rq_tready_r   = 1'b1;
                  end else if (s_axis_rq_tvalid_w) begin
                     s_axis_rq_tready_w   = 1'b1;
                  end else begin // no Writes and Reads
                     s_axis_rq_tready_r   = 1'b1;
                  end
               end
            end
         end

         state_mx[R_CTN]: begin
            if (wait_trn_time == 0) begin
               if (s_axis_rq_tready_i) begin
                  if (s_axis_rq_tvalid_r) begin
                     s_axis_rq_tready_r   = 1'b1;
                  end else if (s_axis_rq_tvalid_w) begin
                     s_axis_rq_tready_w   = 1'b1;
                  end else begin // no Writes and Reads
                     s_axis_rq_tready_r   = 1'b1;
                  end
               end
            end
         end
      endcase
   end

endmodule // BMD_AXIST_RQ_MUX_512
