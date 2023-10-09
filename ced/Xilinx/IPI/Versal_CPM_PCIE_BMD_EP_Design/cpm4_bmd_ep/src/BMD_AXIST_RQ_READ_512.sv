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
// Project    : Everest FPGA PCI Express Integrated Block
// File       : BMD_AXIST_RQ_READ_512.sv
// Version    : 1.0 
//-----------------------------------------------------------------------------

`include "pcie_app_versal_bmd.vh"
`timescale 1ps / 1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_RQ_READ_512 #(
   parameter         AXISTEN_IF_REQ_ALIGNMENT_MODE = 0,
   parameter         AXISTEN_IF_RQ_STRADDLE        = 0,
   parameter         AXISTEN_IF_REQ_PARITY_CHECK   = 0,
   parameter         AXISTEN_IF_ENABLE_CLIENT_TAG  = 0,
   parameter         RQ_AVAIL_TAG_IDX              = 8,
   parameter         RQ_AVAIL_TAG                  = 256,
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

   // AXI-S Requester Request Interface
   output logic [511:0]             s_axis_rq_tdata,
   output logic [15:0]              s_axis_rq_tkeep,
   output logic                     s_axis_rq_tlast,
   output logic                     s_axis_rq_tvalid,
   output logic [182:0]             s_axis_rq_tuser,
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

   input                            mrd_start_i,
   input        [10:0]              mrd_len_i,
   input        [31:0]              mrd_addr_i,
   input        [15:0]              mrd_count_i,
   output logic                     mrd_done_o
);
   `STRUCT_AXI_RQ_IF

   logic [29:0]   rd_addr_31_2, rd_addr_31_2_2nd;

   logic [15:0]   total_mrd_count, total_mrd_count_wire;
   logic [15:0]   r_tcnt, r_tcnt_wire; 
   s_axis_rq_tdata_512  s_axis_rq_tdata_wire;
   s_axis_rq_tdata_512  s_axis_rq_tdata_reg;
   logic [15:0]   s_axis_rq_tkeep_wire;
   logic          s_axis_rq_tlast_wire;
   logic          s_axis_rq_tvalid_wire;
   s_axis_rq_tuser_512  s_axis_rq_tuser_wire;
   s_axis_rq_tuser_512  s_axis_rq_tuser_reg;
   s_axis_rq_tuser_512  s_axis_rq_tuser_w_parity;
   logic [63:0]   s_axis_rq_parity;
   logic          mrd_done_wire;

   logic          client_tag_assigned_0, client_tag_assigned_0_wire;
   logic          client_tag_assigned_1, client_tag_assigned_1_wire;
   logic [RQ_AVAIL_TAG_IDX-1:0]  client_tag_assigned_num_0, client_tag_assigned_num_0_wire;
   logic [RQ_AVAIL_TAG_IDX-1:0]  client_tag_assigned_num_1, client_tag_assigned_num_1_wire;
   logic [7:0]    client_tag_assigned_num_8bit_0;
   logic [7:0]    client_tag_assigned_num_8bit_1;
   logic [RQ_AVAIL_TAG-1:0]      avail_client_tag, avail_client_tag_wire;
   logic [RQ_AVAIL_TAG-1:0]      client_tag_assigned_vec_0;
   logic [RQ_AVAIL_TAG-1:0]      client_tag_assigned_vec_1;
   logic [RQ_AVAIL_TAG-1:0]      client_tag_released_vec_0;
   logic [RQ_AVAIL_TAG-1:0]      client_tag_released_vec_1;
   logic [RQ_AVAIL_TAG-1:0]      client_tag_released_vec_2;
   logic [RQ_AVAIL_TAG-1:0]      client_tag_released_vec_3;

   // Make encoded tags become vectors
genvar var_i;
generate
   for (var_i = 0; var_i < RQ_AVAIL_TAG; var_i = var_i + 1) begin: gen_tag_vec
      assign client_tag_assigned_vec_0[var_i]   = (client_tag_assigned_num_0[RQ_AVAIL_TAG_IDX-1:0] == var_i);
      assign client_tag_assigned_vec_1[var_i]   = (client_tag_assigned_num_1[RQ_AVAIL_TAG_IDX-1:0] == var_i);
      assign client_tag_released_vec_0[var_i]   = (client_tag_released_num_0[RQ_AVAIL_TAG_IDX-1:0] == var_i);
      assign client_tag_released_vec_1[var_i]   = (client_tag_released_num_1[RQ_AVAIL_TAG_IDX-1:0] == var_i);
      assign client_tag_released_vec_2[var_i]   = (client_tag_released_num_2[RQ_AVAIL_TAG_IDX-1:0] == var_i);
      assign client_tag_released_vec_3[var_i]   = (client_tag_released_num_3[RQ_AVAIL_TAG_IDX-1:0] == var_i);
   end   
endgenerate

   assign avail_client_tag_wire  = (avail_client_tag
                                    & ~({RQ_AVAIL_TAG{client_tag_assigned_0_wire}} & client_tag_assigned_vec_0)
                                    & ~({RQ_AVAIL_TAG{client_tag_assigned_1_wire}} & client_tag_assigned_vec_1)
                                    | ({RQ_AVAIL_TAG{client_tag_released_0}} & client_tag_released_vec_0)
                                    | ({RQ_AVAIL_TAG{client_tag_released_1}} & client_tag_released_vec_1)
                                    | ({RQ_AVAIL_TAG{client_tag_released_2}} & client_tag_released_vec_2)
                                    | ({RQ_AVAIL_TAG{client_tag_released_3}} & client_tag_released_vec_3));
   `BMDREG(user_clk, (reset_n & ~init_rst_i), avail_client_tag, avail_client_tag_wire, {RQ_AVAIL_TAG{1'b1}})

   assign client_tag_assigned_num_8bit_0  = 8'b0 | client_tag_assigned_num_0;
   assign client_tag_assigned_num_8bit_1  = 8'b0 | client_tag_assigned_num_1;
   assign tags_all_back = &avail_client_tag | ~AXISTEN_IF_ENABLE_CLIENT_TAG;

   localparam  IDLE        = 0;
   localparam  SEND_RHDR   = 1;  // One Read
   localparam  SEND_RSTD   = 2;  // Two Reads
   localparam  LAST        = 3;

   localparam  STATE_CNT   = 4;

   logic [STATE_CNT-1:0]   state_rq, state_rq_wire;

   assign rd_addr_31_2     = mrd_addr_i[31:2] + mrd_len_i[10:0] * r_tcnt[15:0];
   assign rd_addr_31_2_2nd = mrd_addr_i[31:2] + mrd_len_i[10:0] * (r_tcnt[15:0] + 1);

   always_comb begin
      client_tag_assigned_0_wire       = 1'b0;
      client_tag_assigned_1_wire       = 1'b0;
      client_tag_assigned_num_0_wire   = client_tag_assigned_num_0;
      client_tag_assigned_num_1_wire   = client_tag_assigned_num_1;

      total_mrd_count_wire    = total_mrd_count;
      r_tcnt_wire             = r_tcnt;
      s_axis_rq_tdata_wire    = s_axis_rq_tdata_reg;
      s_axis_rq_tkeep_wire    = s_axis_rq_tkeep;
      s_axis_rq_tlast_wire    = s_axis_rq_tlast;
      s_axis_rq_tvalid_wire   = s_axis_rq_tvalid;
      s_axis_rq_tuser_wire    = s_axis_rq_tuser_reg;
      mrd_done_wire           = mrd_done_o;
      state_rq_wire           = 'd0;

      case (1'b1)
         state_rq[IDLE]: begin
            r_tcnt_wire = 'd0;
            if (mrd_start_i & (mrd_count_i[15:0] != 0) & ~mrd_done_o) begin
               // Latch all the commands
               total_mrd_count_wire    = mrd_count_i;
               if (AXISTEN_IF_RQ_STRADDLE) begin
                  if (mrd_count_i == 1) begin
                     state_rq_wire[SEND_RHDR]   = 1'b1;
                  end else begin // (mrd_count_i != 1)
                     state_rq_wire[SEND_RSTD]   = 1'b1;
                  end
               end else begin // !AXISTEN_IF_RQ_STRADDLE
                  state_rq_wire[SEND_RHDR]   = 1'b1;
               end
            end else begin // no requests
               state_rq_wire[IDLE]  = 1'b1;
            end
         end   // IDLE

         state_rq[SEND_RHDR]: begin // One Read
            if (~s_axis_rq_tvalid | s_axis_rq_tready) begin
               if (avail_client_tag[client_tag_assigned_num_0] | ~AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                  s_axis_rq_tvalid_wire   = 1'b1;
                  s_axis_rq_tdata_wire    = 512'd0;
                  s_axis_rq_tuser_wire    = 137'd0;
                  s_axis_rq_tlast_wire    = 1'b0;
                  s_axis_rq_tkeep_wire    = 'd0;
   
                  if (AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                     client_tag_assigned_0_wire       = 1'b1;
                     client_tag_assigned_num_0_wire   = client_tag_assigned_num_0 + 1;
                     client_tag_assigned_num_1_wire   = client_tag_assigned_num_1 + 1;
                     s_axis_rq_tdata_wire.lh.tag      = client_tag_assigned_num_0;
                  end
                  s_axis_rq_tdata_wire.lh.req_type       = 4'b0000;
                  s_axis_rq_tdata_wire.lh.dword_count    = mrd_len_i;
                  s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, rd_addr_31_2};
                  s_axis_rq_tuser_wire.last_be           = (mrd_len_i == 1)? 8'h00: 8'h0F;
                  s_axis_rq_tuser_wire.first_be          = 8'h0F;
                  s_axis_rq_tuser_wire.addr_offset       = (AXISTEN_IF_REQ_ALIGNMENT_MODE == "TRUE") ? {2'h0,rd_addr_31_2[1:0]} : 4'h0;
                  if (AXISTEN_IF_RQ_STRADDLE) begin
                     s_axis_rq_tuser_wire.is_sop         = 2'b01;
                     s_axis_rq_tuser_wire.is_eop         = 2'b01;
                     s_axis_rq_tuser_wire.is_sop0_ptr    = 2'b00;                  
                     s_axis_rq_tuser_wire.is_eop0_ptr    = 4'd3;                  
                  end else begin
                     s_axis_rq_tlast_wire                = 1'b1;
                     s_axis_rq_tkeep_wire                = 16'h000F;
                  end
   
                  // Update flags
                  total_mrd_count_wire       = total_mrd_count - 1;
                  r_tcnt_wire                = r_tcnt + 1;
                     
                  if (total_mrd_count == 1) begin  // All reads are done
                     state_rq_wire[LAST]        = 1'b1;
                  end else begin // (total_mrd_count != 1)
                     state_rq_wire[SEND_RHDR]   = 1'b1;
                  end
               end else begin // no available tag
                  state_rq_wire[SEND_RHDR]   = 1'b1;
               end
            end else begin // ~s_axis_rq_tready
               state_rq_wire[SEND_RHDR]   = 1'b1;
            end
         end   // SEND_RHDR

         state_rq[SEND_RSTD]: begin // Two Reads, only valid when straddle is enabled
            if (~s_axis_rq_tvalid | s_axis_rq_tready) begin
               if ((avail_client_tag[client_tag_assigned_num_0] & avail_client_tag[client_tag_assigned_num_1])
                   | ~AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                  s_axis_rq_tvalid_wire   = 1'b1;
                  s_axis_rq_tdata_wire    = 512'd0;
                  s_axis_rq_tuser_wire    = 137'd0;
                  s_axis_rq_tlast_wire    = 1'b0;
                  s_axis_rq_tkeep_wire    = 'd0;

                  if (AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                     client_tag_assigned_0_wire       = 1'b1;
                     client_tag_assigned_1_wire       = 1'b1;
                     client_tag_assigned_num_0_wire   = client_tag_assigned_num_0 + 2;
                     client_tag_assigned_num_1_wire   = client_tag_assigned_num_1 + 2;
                     s_axis_rq_tdata_wire.lh.tag      = client_tag_assigned_num_8bit_0;
                     s_axis_rq_tdata_wire.uh.tag      = client_tag_assigned_num_8bit_1;
                  end
                  s_axis_rq_tdata_wire.uh.req_type       = 4'b0000;
                  s_axis_rq_tdata_wire.uh.dword_count    = mrd_len_i;
                  s_axis_rq_tdata_wire.uh.addr_63_2      = {32'd0, rd_addr_31_2_2nd};
                  s_axis_rq_tdata_wire.lh.req_type       = 4'b0000;
                  s_axis_rq_tdata_wire.lh.dword_count    = mrd_len_i;
                  s_axis_rq_tdata_wire.lh.addr_63_2      = {32'd0, rd_addr_31_2};
                  s_axis_rq_tuser_wire.last_be           = (mrd_len_i == 1)? 8'h00: 8'hFF;
                  s_axis_rq_tuser_wire.first_be          = 8'hFF;
                  if (AXISTEN_IF_RQ_STRADDLE) begin
                     s_axis_rq_tuser_wire.is_sop         = 2'b11;
                     s_axis_rq_tuser_wire.is_eop         = 2'b11;
                     s_axis_rq_tuser_wire.is_sop0_ptr    = 2'b00;                  
                     s_axis_rq_tuser_wire.is_sop1_ptr    = 2'b10;                  
                     s_axis_rq_tuser_wire.is_eop0_ptr    = 4'd3;                  
                     s_axis_rq_tuser_wire.is_eop1_ptr    = 4'd11;                  
                  end else begin
                     s_axis_rq_tlast_wire                = 1'b1;
                     s_axis_rq_tkeep_wire                = 16'h000F;
                  end
   
                  // Update flags
                  total_mrd_count_wire       = total_mrd_count - 2;
                  r_tcnt_wire                = r_tcnt + 2;
   
                  if (total_mrd_count == 3) begin  // One read left after this state
                     state_rq_wire[SEND_RHDR]   = 1'b1;                        
                  end else if (total_mrd_count == 2) begin  // All reads are done
                     state_rq_wire[LAST]        = 1'b1;
                  end else begin // (total_mrd_count != 2 or 3)
                     state_rq_wire[SEND_RSTD]   = 1'b1;
                  end
               end else begin // no available tag
                  state_rq_wire[SEND_RSTD]   = 1'b1;
               end
            end else begin // ~s_axis_rq_tready
               state_rq_wire[SEND_RSTD]   = 1'b1;
            end
         end   // SEND_RSTD

         state_rq[LAST]: begin
            if (s_axis_rq_tready) begin
               s_axis_rq_tvalid_wire   = 1'b0;
               mrd_done_wire           = 1'b1;
               state_rq_wire[IDLE]     = 1'b1;
            end else begin // (~s_axis_rq_tready)
               state_rq_wire[LAST]     = 1'b1;
            end
         end   // LAST
      endcase
   end

   // Generate parity for data
generate
   for (var_i = 0; var_i < 64; var_i = var_i + 1) begin: rq_parity_generation
      assign s_axis_rq_parity[var_i] =  ~(^s_axis_rq_tdata_wire[8*(var_i+1)-1:8*var_i]);
   end
endgenerate

   always_comb begin
      s_axis_rq_tuser_w_parity         = s_axis_rq_tuser_wire;
      s_axis_rq_tuser_w_parity.parity  = AXISTEN_IF_REQ_PARITY_CHECK? s_axis_rq_parity: 64'd0;
   end

   `BMDREG(user_clk, (reset_n & ~init_rst_i), total_mrd_count, total_mrd_count_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), r_tcnt, r_tcnt_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tdata_reg, s_axis_rq_tdata_wire, 512'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tkeep, s_axis_rq_tkeep_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tlast, s_axis_rq_tlast_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tvalid, s_axis_rq_tvalid_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tuser_reg, s_axis_rq_tuser_w_parity, 137'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), mrd_done_o, mrd_done_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), state_rq, state_rq_wire, 'd1)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_0, client_tag_assigned_0_wire, 1'b1)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_1, client_tag_assigned_1_wire, 1'b1)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_num_0, client_tag_assigned_num_0_wire, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_num_1, client_tag_assigned_num_1_wire, 'd1)

   assign s_axis_rq_tdata  = s_axis_rq_tdata_reg;
   assign s_axis_rq_tuser  = {{46{1'b0}},s_axis_rq_tuser_reg};

endmodule // BMD_AXIST_RQ_READ_512
