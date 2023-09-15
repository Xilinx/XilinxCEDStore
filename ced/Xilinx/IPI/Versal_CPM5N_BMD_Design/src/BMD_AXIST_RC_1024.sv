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

`include "pcie_app_uscale_bmd_1024.vh"
`timescale 1ps / 1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_RC_1024 #(
   parameter         AXISTEN_IF_REQ_ALIGNMENT_MODE = 0,
   parameter         AXISTEN_IF_RC_STRADDLE        = 2'b00,
   parameter         AXISTEN_IF_REQ_PARITY_CHECK   = 0,
   parameter         AXI4_RC_TUSER_WIDTH           = 161,
   parameter         AXISTEN_IF_ENABLE_CLIENT_TAG  = 0,
   parameter         RQ_AVAIL_TAG_IDX              = 8,   
   parameter         C_DATA_WIDTH                  = 1024,
   parameter         KEEP_WIDTH                    = C_DATA_WIDTH/32,
   parameter         TCQ                           = 1
) (
   // Clock and Reset
   input                            user_clk,
   input                            reset_n,
   input                            init_rst_i,

   // AXIST RC I/F
   (*mark_debug*) input       [C_DATA_WIDTH-1:0]         m_axis_rc_tdata,
   (*mark_debug*) input       [AXI4_RC_TUSER_WIDTH-1:0]  m_axis_rc_tuser,
   (*mark_debug*) input       [KEEP_WIDTH-1:0]           m_axis_rc_tkeep,
   (*mark_debug*) input                                  m_axis_rc_tlast,
   (*mark_debug*) output logic                           m_axis_rc_tready,
   (*mark_debug*) input                                  m_axis_rc_tvalid,

   // Client Tag
   (*mark_debug*)(*keep*)output logic                     client_tag_released_0,
   (*mark_debug*)(*keep*)output logic                     client_tag_released_1,
   (*mark_debug*)(*keep*)output logic                     client_tag_released_2,
   (*mark_debug*)(*keep*)output logic                     client_tag_released_3,
   (*mark_debug*)(*keep*)output logic                     client_tag_released_4,
   (*mark_debug*)(*keep*)output logic                     client_tag_released_5,
   (*mark_debug*)(*keep*)output logic                     client_tag_released_6,
   (*mark_debug*)(*keep*)output logic                     client_tag_released_7,

   (*mark_debug*)(*keep*)output logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_0,
   (*mark_debug*)(*keep*)output logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_1,
   (*mark_debug*)(*keep*)output logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_2,
   (*mark_debug*)(*keep*)output logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_3,
   (*mark_debug*)(*keep*)output logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_4,
   (*mark_debug*)(*keep*)output logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_5,
   (*mark_debug*)(*keep*)output logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_6,
   (*mark_debug*)(*keep*)output logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_7,

   input                                          cfg_10b_tag_requester_enable,

   // CPLD I/F to EP_MEM
   (*mark_debug*)input       [31:0]               cpld_data_i,
   (*mark_debug*)(*keep*)output logic [31:0]              cpld_found_o,
   (*mark_debug*)(*keep*)output logic [31:0]              cpld_data_size_o,
   (*mark_debug*)(*keep*)output logic                     cpld_data_err_o,
   (*mark_debug*)output logic                     cpld_parity_err_o
);
   `STRUCT_AXI_RC_IF_1024

   (*mark_debug*) logic [7:0]    dqw_is_header;
   (*mark_debug*) logic [23:0]   dqw_is_end;
   (*mark_debug*) logic [7:0]    dqw_error_wire;
   (*mark_debug*) logic [7:0]    dqw_parity_error_wire;
   (*mark_debug*)(*keep*)logic          client_tag_released_0_wire;
   (*mark_debug*)(*keep*)logic          client_tag_released_1_wire;
   (*mark_debug*)(*keep*)logic          client_tag_released_2_wire;
   (*mark_debug*)(*keep*)logic          client_tag_released_3_wire;
   (*mark_debug*)(*keep*)logic          client_tag_released_4_wire;
   (*mark_debug*)(*keep*)logic          client_tag_released_5_wire;
   (*mark_debug*)(*keep*)logic          client_tag_released_6_wire;
   (*mark_debug*)(*keep*)logic          client_tag_released_7_wire;
   (*mark_debug*)(*keep*)logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_0_wire;
   (*mark_debug*)(*keep*)logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_1_wire;
   (*mark_debug*)(*keep*)logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_2_wire;
   (*mark_debug*)(*keep*)logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_3_wire;
   (*mark_debug*)(*keep*)logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_4_wire;
   (*mark_debug*)(*keep*)logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_5_wire;
   (*mark_debug*)(*keep*)logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_6_wire;
   (*mark_debug*)(*keep*)logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_7_wire;
   s_axis_rc_tdata_1024  m_axis_rc_tdata_in;
   s_axis_rc_tuser_1024  m_axis_rc_tuser_in;
   //logic [3:0]    dqw_is_first_qw0; // only used in address-align

   assign m_axis_rc_tdata_in = m_axis_rc_tdata;
   assign m_axis_rc_tuser_in = m_axis_rc_tuser;

   (*mark_debug*)(*keep*) logic [7:0]    cpld_found_dw;
   logic [10:0]   cpld_data_size [7:0];
   logic [31:0]   cpld_found_wire;
   logic [31:0]   cpld_data_size_wire;
   (*mark_debug*)(*keep*) logic          cpld_data_err_wire;
   logic          cpld_parity_err_wire;
   logic [127:0]   exp_parity;

   // Header or data
   assign dqw_is_header[0] =  m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 3'd0);

   assign dqw_is_header[1] = (m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 3'd1)) |
                             (m_axis_rc_tuser_in.is_sop[1] & (m_axis_rc_tuser_in.is_sop1_ptr == 3'd1));

   assign dqw_is_header[2] = (m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 3'd2)) |
                             (m_axis_rc_tuser_in.is_sop[1] & (m_axis_rc_tuser_in.is_sop1_ptr == 3'd2)) |
                             (m_axis_rc_tuser_in.is_sop[2] & (m_axis_rc_tuser_in.is_sop2_ptr == 3'd2));

   assign dqw_is_header[3] = (m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 3'd3)) |
                             (m_axis_rc_tuser_in.is_sop[1] & (m_axis_rc_tuser_in.is_sop1_ptr == 3'd3)) |
                             (m_axis_rc_tuser_in.is_sop[2] & (m_axis_rc_tuser_in.is_sop2_ptr == 3'd3)) |
                             (m_axis_rc_tuser_in.is_sop[3] & (m_axis_rc_tuser_in.is_sop3_ptr == 3'd3));

   assign dqw_is_header[4] = (m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 3'd4)) |
                             (m_axis_rc_tuser_in.is_sop[1] & (m_axis_rc_tuser_in.is_sop1_ptr == 3'd4)) |
                             (m_axis_rc_tuser_in.is_sop[2] & (m_axis_rc_tuser_in.is_sop2_ptr == 3'd4)) |
                             (m_axis_rc_tuser_in.is_sop[3] & (m_axis_rc_tuser_in.is_sop3_ptr == 3'd4)) |
                             (m_axis_rc_tuser_in.is_sop[4] & (m_axis_rc_tuser_in.is_sop4_ptr == 3'd4));

   assign dqw_is_header[5] = (m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 3'd5)) |
                             (m_axis_rc_tuser_in.is_sop[1] & (m_axis_rc_tuser_in.is_sop1_ptr == 3'd5)) |
                             (m_axis_rc_tuser_in.is_sop[2] & (m_axis_rc_tuser_in.is_sop2_ptr == 3'd5)) |
                             (m_axis_rc_tuser_in.is_sop[3] & (m_axis_rc_tuser_in.is_sop3_ptr == 3'd5)) |
                             (m_axis_rc_tuser_in.is_sop[4] & (m_axis_rc_tuser_in.is_sop4_ptr == 3'd5)) |
                             (m_axis_rc_tuser_in.is_sop[5] & (m_axis_rc_tuser_in.is_sop5_ptr == 3'd5));

   assign dqw_is_header[6] = (m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 3'd6)) |
                             (m_axis_rc_tuser_in.is_sop[1] & (m_axis_rc_tuser_in.is_sop1_ptr == 3'd6)) |
                             (m_axis_rc_tuser_in.is_sop[2] & (m_axis_rc_tuser_in.is_sop2_ptr == 3'd6)) |
                             (m_axis_rc_tuser_in.is_sop[3] & (m_axis_rc_tuser_in.is_sop3_ptr == 3'd6)) |
                             (m_axis_rc_tuser_in.is_sop[4] & (m_axis_rc_tuser_in.is_sop4_ptr == 3'd6)) |
                             (m_axis_rc_tuser_in.is_sop[5] & (m_axis_rc_tuser_in.is_sop5_ptr == 3'd6)) |
                             (m_axis_rc_tuser_in.is_sop[6] & (m_axis_rc_tuser_in.is_sop6_ptr == 3'd6));

   assign dqw_is_header[7] = (m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 3'd7)) |
                             (m_axis_rc_tuser_in.is_sop[1] & (m_axis_rc_tuser_in.is_sop1_ptr == 3'd7)) |
                             (m_axis_rc_tuser_in.is_sop[2] & (m_axis_rc_tuser_in.is_sop2_ptr == 3'd7)) |
                             (m_axis_rc_tuser_in.is_sop[3] & (m_axis_rc_tuser_in.is_sop3_ptr == 3'd7)) |
                             (m_axis_rc_tuser_in.is_sop[4] & (m_axis_rc_tuser_in.is_sop4_ptr == 3'd7)) |
                             (m_axis_rc_tuser_in.is_sop[5] & (m_axis_rc_tuser_in.is_sop5_ptr == 3'd7)) |
                             (m_axis_rc_tuser_in.is_sop[6] & (m_axis_rc_tuser_in.is_sop6_ptr == 3'd7)) |
                             (m_axis_rc_tuser_in.is_sop[7] & (m_axis_rc_tuser_in.is_sop7_ptr == 3'd7));

// only used in address-aligned
   //assign dqw_is_first_qw0[0] =  'd0;
   //assign dqw_is_first_qw0[1] =  (AXISTEN_IF_REQ_ALIGNMENT_MODE == "TRUE") ? m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 2'd0) : 'd0;
   //assign dqw_is_first_qw0[2] =  'd0;
   //assign dqw_is_first_qw0[3] =  'd0;

   // End
generate
   if (AXISTEN_IF_RC_STRADDLE == 2'b01) begin: straddle_2_eop
      assign dqw_is_end[2:0]  =  (m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd0))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0;

      assign dqw_is_end[5:3]  = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd1))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd1))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0);

      assign dqw_is_end[8:6]  = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd2))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd2))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) ;

      assign dqw_is_end[11:9] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd3))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd3))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) ;

      assign dqw_is_end[14:12] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd4))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd4))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) ;

      assign dqw_is_end[17:15] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd5))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd5))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) ;

      assign dqw_is_end[20:18] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd6))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd6))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) ;

      assign dqw_is_end[23:21] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) ;

   end else if (AXISTEN_IF_RC_STRADDLE == 2'b10) begin: straddle_4_eop
      assign dqw_is_end[2:0]  =  (m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd0))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0;

      assign dqw_is_end[5:3]  = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd1))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd1))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0);

      assign dqw_is_end[8:6]  = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd2))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd2))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[4:2] == 3'd2))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0);

      assign dqw_is_end[11:9] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd3))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd3))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[4:2] == 3'd3))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[3] & (m_axis_rc_tuser_in.is_eop3_ptr[4:2] == 3'd3))? {1'b1, m_axis_rc_tuser_in.is_eop3_ptr[1:0]}: 3'd0);

      assign dqw_is_end[14:12] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd4))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd4))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[4:2] == 3'd4))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[3] & (m_axis_rc_tuser_in.is_eop3_ptr[4:2] == 3'd4))? {1'b1, m_axis_rc_tuser_in.is_eop3_ptr[1:0]}: 3'd0) ;

      assign dqw_is_end[17:15] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd5))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd5))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[4:2] == 3'd5))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[3] & (m_axis_rc_tuser_in.is_eop3_ptr[4:2] == 3'd5))? {1'b1, m_axis_rc_tuser_in.is_eop3_ptr[1:0]}: 3'd0) ;

      assign dqw_is_end[20:18] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd6))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd6))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[4:2] == 3'd6))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[3] & (m_axis_rc_tuser_in.is_eop3_ptr[4:2] == 3'd6))? {1'b1, m_axis_rc_tuser_in.is_eop3_ptr[1:0]}: 3'd0) ;

      assign dqw_is_end[23:21] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[3] & (m_axis_rc_tuser_in.is_eop3_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop3_ptr[1:0]}: 3'd0) ;

   end else if (AXISTEN_IF_RC_STRADDLE == 2'b11) begin: straddle_8_eop
      assign dqw_is_end[2:0]  =  (m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd0))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0;

      assign dqw_is_end[5:3]  = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd1))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd1))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0);

      assign dqw_is_end[8:6]  = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd2))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd2))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[4:2] == 3'd2))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0);

      assign dqw_is_end[11:9] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd3))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd3))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[4:2] == 3'd3))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[3] & (m_axis_rc_tuser_in.is_eop3_ptr[4:2] == 3'd3))? {1'b1, m_axis_rc_tuser_in.is_eop3_ptr[1:0]}: 3'd0);

      assign dqw_is_end[14:12] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd4))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd4))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[4:2] == 3'd4))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[3] & (m_axis_rc_tuser_in.is_eop3_ptr[4:2] == 3'd4))? {1'b1, m_axis_rc_tuser_in.is_eop3_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[4] & (m_axis_rc_tuser_in.is_eop4_ptr[4:2] == 3'd4))? {1'b1, m_axis_rc_tuser_in.is_eop4_ptr[1:0]}: 3'd0);

      assign dqw_is_end[17:15] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd5))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd5))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[4:2] == 3'd5))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[3] & (m_axis_rc_tuser_in.is_eop3_ptr[4:2] == 3'd5))? {1'b1, m_axis_rc_tuser_in.is_eop3_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[4] & (m_axis_rc_tuser_in.is_eop4_ptr[4:2] == 3'd5))? {1'b1, m_axis_rc_tuser_in.is_eop4_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[5] & (m_axis_rc_tuser_in.is_eop5_ptr[4:2] == 3'd5))? {1'b1, m_axis_rc_tuser_in.is_eop5_ptr[1:0]}: 3'd0);

      assign dqw_is_end[20:18] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd6))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd6))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[4:2] == 3'd6))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[3] & (m_axis_rc_tuser_in.is_eop3_ptr[4:2] == 3'd6))? {1'b1, m_axis_rc_tuser_in.is_eop3_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[4] & (m_axis_rc_tuser_in.is_eop4_ptr[4:2] == 3'd6))? {1'b1, m_axis_rc_tuser_in.is_eop4_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[5] & (m_axis_rc_tuser_in.is_eop5_ptr[4:2] == 3'd6))? {1'b1, m_axis_rc_tuser_in.is_eop5_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[6] & (m_axis_rc_tuser_in.is_eop6_ptr[4:2] == 3'd6))? {1'b1, m_axis_rc_tuser_in.is_eop6_ptr[1:0]}: 3'd0);

      assign dqw_is_end[23:21] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[3] & (m_axis_rc_tuser_in.is_eop3_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop3_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[4] & (m_axis_rc_tuser_in.is_eop4_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop4_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[5] & (m_axis_rc_tuser_in.is_eop5_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop5_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[6] & (m_axis_rc_tuser_in.is_eop6_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop6_ptr[1:0]}: 3'd0) |
                                 ((m_axis_rc_tuser_in.is_eop[7] & (m_axis_rc_tuser_in.is_eop7_ptr[4:2] == 3'd7))? {1'b1, m_axis_rc_tuser_in.is_eop7_ptr[1:0]}: 3'd0);

   end else begin: non_straddle_using_tlast_tkeep
      assign dqw_is_end[1:0]   = 2'b0;  // Not used by checker
      assign dqw_is_end[2]     = m_axis_rc_tlast & ~m_axis_rc_tkeep[4]  & (|m_axis_rc_tkeep[3:0]);
      assign dqw_is_end[4:3]   = 2'b0;  // Not used by checker
      assign dqw_is_end[5]     = m_axis_rc_tlast & ~m_axis_rc_tkeep[8]  & (|m_axis_rc_tkeep[7:4]);
      assign dqw_is_end[7:6]   = 2'b0;  // Not used by checker
      assign dqw_is_end[8]     = m_axis_rc_tlast & ~m_axis_rc_tkeep[12] & (|m_axis_rc_tkeep[11:8]);
      assign dqw_is_end[10:9]  = 2'b0;  // Not used by checker
      assign dqw_is_end[11]    = m_axis_rc_tlast & ~m_axis_rc_tkeep[16] & (|m_axis_rc_tkeep[15:12]);
      assign dqw_is_end[13:12] = 2'b0;  // Not used by checker
      assign dqw_is_end[14]    = m_axis_rc_tlast & ~m_axis_rc_tkeep[20] & (|m_axis_rc_tkeep[19:16]);
      assign dqw_is_end[16:15] = 2'b0;  // Not used by checker
      assign dqw_is_end[17]    = m_axis_rc_tlast & ~m_axis_rc_tkeep[24] & (|m_axis_rc_tkeep[23:20]);
      assign dqw_is_end[19:18] = 2'b0;  // Not used by checker
      assign dqw_is_end[20]    = m_axis_rc_tlast & ~m_axis_rc_tkeep[28] & (|m_axis_rc_tkeep[27:24]);
      assign dqw_is_end[22:21] = 2'b0;  // Not used by checker
      assign dqw_is_end[23]    = m_axis_rc_tlast                        & (|m_axis_rc_tkeep[31:28]);
   end
endgenerate

genvar var_i;
generate
   for (var_i = 0; var_i < 128; var_i = var_i + 1) begin: rc_parity_generation
      // Generate expected parity for data
      assign exp_parity[var_i]   = ~(^m_axis_rc_tdata[8*(var_i+1)-1:8*var_i]);
   end
   for (var_i = 0; var_i < 8; var_i = var_i + 1) begin: dqw_generation
      // Check errors
      if(AXISTEN_IF_REQ_ALIGNMENT_MODE != "TRUE") // DW-aligned
        assign dqw_error_wire[var_i]  = f_rc_dqw_error_check(dqw_is_header[var_i], dqw_is_end[var_i*3+:3], m_axis_rc_tdata[var_i*128+:128], {4{cpld_data_i}}, m_axis_rc_tuser_in.byte_en[var_i*16+:16]);
      else // Address aligned - not supported
        assign dqw_error_wire[var_i]  = 1'b0;
        //assign dqw_error_wire[var_i]  = f_rc_dqw_error_check_addr_align(dqw_is_header[var_i], dqw_is_first_qw0[var_i], dqw_is_end[var_i*3+:3], m_axis_rc_tdata[var_i*128+:128], {4{cpld_data_i}}, m_axis_rc_tuser_in.byte_en[var_i*16+:16], m_axis_rc_tdata_in.address[3:2]);

      // Check parity
      assign dqw_parity_error_wire[var_i] = f_rc_dqw_parity_check(dqw_is_header[var_i], m_axis_rc_tuser_in.parity[var_i*16+:16], exp_parity[var_i*16+:16], m_axis_rc_tuser_in.byte_en[var_i*16+:16]);
      // Request Completed
      assign cpld_found_dw[var_i]   = dqw_is_header[var_i]? m_axis_rc_tdata[var_i*128+30]: 1'b0;
      // Dword Count
      assign cpld_data_size[var_i]  = dqw_is_header[var_i]? m_axis_rc_tdata[var_i*128+42:var_i*128+32]: 11'd0;
   end
endgenerate

   // Log results
   always @(*) begin
      if (m_axis_rc_tvalid) begin
         cpld_found_wire      = cpld_found_o + {31'd0, cpld_found_dw[0]} + {31'd0, cpld_found_dw[1]} + {31'd0, cpld_found_dw[2]} + {31'd0, cpld_found_dw[3]}
                                             + {31'd0, cpld_found_dw[4]} + {31'd0, cpld_found_dw[5]} + {31'd0, cpld_found_dw[6]} + {31'd0, cpld_found_dw[7]};
         cpld_data_size_wire  = cpld_data_size_o + {21'd0, cpld_data_size[0]} + {21'd0, cpld_data_size[1]} + {21'd0, cpld_data_size[2]} + {21'd0, cpld_data_size[3]} 
                                                 + {21'd0, cpld_data_size[4]} + {21'd0, cpld_data_size[5]} + {21'd0, cpld_data_size[6]} + {21'd0, cpld_data_size[7]} ;
         cpld_data_err_wire   = (|dqw_error_wire) | cpld_data_err_o;
         cpld_parity_err_wire = AXISTEN_IF_REQ_PARITY_CHECK ? (|dqw_parity_error_wire): 1'b0;
         client_tag_released_0_wire = cpld_found_dw[0] & AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_1_wire = cpld_found_dw[1] & AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_2_wire = cpld_found_dw[2] & AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_3_wire = cpld_found_dw[3] & AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_4_wire = cpld_found_dw[4] & AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_5_wire = cpld_found_dw[5] & AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_6_wire = cpld_found_dw[6] & AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_7_wire = cpld_found_dw[7] & AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_num_0_wire   = {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata[128*0+47], m_axis_rc_tdata[128*0+31]} : 2'b00), m_axis_rc_tdata[128*0+71:128*0+64]}; //: 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_1_wire   = {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata[128*1+47], m_axis_rc_tdata[128*1+31]} : 2'b00), m_axis_rc_tdata[128*1+71:128*1+64]}; //: 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_2_wire   = {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata[128*2+47], m_axis_rc_tdata[128*2+31]} : 2'b00), m_axis_rc_tdata[128*2+71:128*2+64]}; //: 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_3_wire   = {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata[128*3+47], m_axis_rc_tdata[128*3+31]} : 2'b00), m_axis_rc_tdata[128*3+71:128*3+64]}; //: 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_4_wire   = {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata[128*4+47], m_axis_rc_tdata[128*4+31]} : 2'b00), m_axis_rc_tdata[128*4+71:128*4+64]}; //: 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_5_wire   = {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata[128*5+47], m_axis_rc_tdata[128*5+31]} : 2'b00), m_axis_rc_tdata[128*5+71:128*5+64]}; //: 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_6_wire   = {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata[128*6+47], m_axis_rc_tdata[128*6+31]} : 2'b00), m_axis_rc_tdata[128*6+71:128*6+64]}; //: 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_7_wire   = {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata[128*7+47], m_axis_rc_tdata[128*7+31]} : 2'b00), m_axis_rc_tdata[128*7+71:128*7+64]}; //: 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
      end else begin
         cpld_found_wire      = cpld_found_o;
         cpld_data_size_wire  = cpld_data_size_o;
         cpld_data_err_wire   = cpld_data_err_o;
         cpld_parity_err_wire = 1'b0;
         client_tag_released_0_wire = 1'b0;
         client_tag_released_1_wire = 1'b0;
         client_tag_released_2_wire = 1'b0;
         client_tag_released_3_wire = 1'b0;
         client_tag_released_4_wire = 1'b0;
         client_tag_released_5_wire = 1'b0;
         client_tag_released_6_wire = 1'b0;
         client_tag_released_7_wire = 1'b0;
         client_tag_released_num_0_wire   = 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}}; //client_tag_released_num_0;
         client_tag_released_num_1_wire   = 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}}; //client_tag_released_num_1;
         client_tag_released_num_2_wire   = 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}}; //client_tag_released_num_2;
         client_tag_released_num_3_wire   = 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}}; //client_tag_released_num_3;
         client_tag_released_num_4_wire   = 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}}; //client_tag_released_num_4;
         client_tag_released_num_5_wire   = 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}}; //client_tag_released_num_5;
         client_tag_released_num_6_wire   = 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}}; //client_tag_released_num_6;
         client_tag_released_num_7_wire   = 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}}; //client_tag_released_num_7;
      end
   end

   (*keep*)(*mark_debug*) reg [7:0] cpld_found_dw_d1;
   (*keep*)(*mark_debug*) reg [9:0] rc_tdata_10btag;
   (*keep*)(*mark_debug*) reg       m_axis_rc_tvalid_d1;
   (*keep*)(*mark_debug*) reg [1023:0]      m_axis_rc_tdata_d1;
   (*keep*)(*mark_debug*) reg       debug_client_tag_released_0;
   (*keep*)(*mark_debug*) reg [9:0] debug_client_tag_released_num_0;

   always @(posedge user_clk)
   begin
     cpld_found_dw_d1 <= cpld_found_dw;
     rc_tdata_10btag  <= {m_axis_rc_tdata[47],m_axis_rc_tdata[31],m_axis_rc_tdata[71:64]};
     m_axis_rc_tvalid_d1 <= m_axis_rc_tvalid;
     m_axis_rc_tdata_d1  <= m_axis_rc_tdata;

     if (m_axis_rc_tvalid_d1)
     begin
       debug_client_tag_released_0 <= cpld_found_dw_d1[0];
       debug_client_tag_released_num_0 <= cfg_10b_tag_requester_enable ? rc_tdata_10btag : {2'b00,rc_tdata_10btag[7:0]}; 
     end
     else
     begin
       debug_client_tag_released_0 <= 0;
     end
   end

   always @ (posedge user_clk)
   begin
     //if(~reset_n)
     //begin
     //    client_tag_released_0       <= 1'b0;
     //    client_tag_released_1       <= 1'b0;
     //    client_tag_released_2       <= 1'b0;
     //    client_tag_released_3       <= 1'b0;
     //    client_tag_released_4       <= 1'b0;
     //    client_tag_released_5       <= 1'b0;
     //    client_tag_released_6       <= 1'b0;
     //    client_tag_released_7       <= 1'b0;
     //    client_tag_released_num_0   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_1   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_2   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_3   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_4   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_5   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_6   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_7   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //end
     //else if(init_rst_i)
     //begin
     //    client_tag_released_0       <= 1'b0;
     //    client_tag_released_1       <= 1'b0;
     //    client_tag_released_2       <= 1'b0;
     //    client_tag_released_3       <= 1'b0;
     //    client_tag_released_4       <= 1'b0;
     //    client_tag_released_5       <= 1'b0;
     //    client_tag_released_6       <= 1'b0;
     //    client_tag_released_7       <= 1'b0;
     //    client_tag_released_num_0   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_1   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_2   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_3   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_4   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_5   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_6   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //    client_tag_released_num_7   <= 'b0; //{RQ_AVAIL_TAG_IDX{1'b0}};
     //end
     //else if (m_axis_rc_tvalid)
     if (m_axis_rc_tvalid_d1)
     begin
         client_tag_released_0       <= cpld_found_dw_d1[0] ;//& AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_1       <= cpld_found_dw_d1[1] ;//& AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_2       <= cpld_found_dw_d1[2] ;//& AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_3       <= cpld_found_dw_d1[3] ;//& AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_4       <= cpld_found_dw_d1[4] ;//& AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_5       <= cpld_found_dw_d1[5] ;//& AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_6       <= cpld_found_dw_d1[6] ;//& AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_7       <= cpld_found_dw_d1[7] ;//& AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_num_0   <= {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata_d1[128*0+47],m_axis_rc_tdata_d1[128*0+31]} : 2'b00), m_axis_rc_tdata_d1[128*0+71:128*0+64]}; //: {RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_1   <= {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata_d1[128*1+47],m_axis_rc_tdata_d1[128*1+31]} : 2'b00), m_axis_rc_tdata_d1[128*1+71:128*1+64]}; //: {RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_2   <= {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata_d1[128*2+47],m_axis_rc_tdata_d1[128*2+31]} : 2'b00), m_axis_rc_tdata_d1[128*2+71:128*2+64]}; //: {RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_3   <= {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata_d1[128*3+47],m_axis_rc_tdata_d1[128*3+31]} : 2'b00), m_axis_rc_tdata_d1[128*3+71:128*3+64]}; //: {RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_4   <= {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata_d1[128*4+47],m_axis_rc_tdata_d1[128*4+31]} : 2'b00), m_axis_rc_tdata_d1[128*4+71:128*4+64]}; //: {RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_5   <= {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata_d1[128*5+47],m_axis_rc_tdata_d1[128*5+31]} : 2'b00), m_axis_rc_tdata_d1[128*5+71:128*5+64]}; //: {RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_6   <= {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata_d1[128*6+47],m_axis_rc_tdata_d1[128*6+31]} : 2'b00), m_axis_rc_tdata_d1[128*6+71:128*6+64]}; //: {RQ_AVAIL_TAG_IDX{1'b0}};
         client_tag_released_num_7   <= {(cfg_10b_tag_requester_enable ? {m_axis_rc_tdata_d1[128*7+47],m_axis_rc_tdata_d1[128*7+31]} : 2'b00), m_axis_rc_tdata_d1[128*7+71:128*7+64]}; //: {RQ_AVAIL_TAG_IDX{1'b0}};
     end
     else 
     begin
         client_tag_released_0       <= 'd0;
         client_tag_released_1       <= 'd0;
         client_tag_released_2       <= 'd0;
         client_tag_released_3       <= 'd0;
         client_tag_released_4       <= 'd0;
         client_tag_released_5       <= 'd0;
         client_tag_released_6       <= 'd0;
         client_tag_released_7       <= 'd0;
         //client_tag_released_num_0   <= {RQ_AVAIL_TAG_IDX{1'b0}};
         //client_tag_released_num_1   <= {RQ_AVAIL_TAG_IDX{1'b0}};
         //client_tag_released_num_2   <= {RQ_AVAIL_TAG_IDX{1'b0}};
         //client_tag_released_num_3   <= {RQ_AVAIL_TAG_IDX{1'b0}};
         //client_tag_released_num_4   <= {RQ_AVAIL_TAG_IDX{1'b0}};
         //client_tag_released_num_5   <= {RQ_AVAIL_TAG_IDX{1'b0}};
         //client_tag_released_num_6   <= {RQ_AVAIL_TAG_IDX{1'b0}};
         //client_tag_released_num_7   <= {RQ_AVAIL_TAG_IDX{1'b0}};
     end
   end

   `BMDREG(user_clk, reset_n, m_axis_rc_tready, 1'b1, 1'b0)          // Deassert tready while reset  // ready modulation later 09.03.2015
   `BMDREG(user_clk, (reset_n & ~init_rst_i), cpld_found_o, cpld_found_wire, 32'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), cpld_data_size_o, cpld_data_size_wire, 32'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), cpld_data_err_o, cpld_data_err_wire, 1'b0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), cpld_parity_err_o, cpld_parity_err_wire, 1'b0)
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_0, client_tag_released_0_wire, 1'b0)
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_1, client_tag_released_1_wire, 1'b0)
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_2, client_tag_released_2_wire, 1'b0)
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_3, client_tag_released_3_wire, 1'b0)
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_4, client_tag_released_4_wire, 1'b0)
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_5, client_tag_released_5_wire, 1'b0)
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_6, client_tag_released_6_wire, 1'b0)
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_7, client_tag_released_7_wire, 1'b0)
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_num_0, client_tag_released_num_0_wire, {RQ_AVAIL_TAG_IDX{1'b0}})
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_num_1, client_tag_released_num_1_wire, {RQ_AVAIL_TAG_IDX{1'b0}})
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_num_2, client_tag_released_num_2_wire, {RQ_AVAIL_TAG_IDX{1'b0}})
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_num_3, client_tag_released_num_3_wire, {RQ_AVAIL_TAG_IDX{1'b0}})
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_num_4, client_tag_released_num_4_wire, {RQ_AVAIL_TAG_IDX{1'b0}})
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_num_5, client_tag_released_num_5_wire, {RQ_AVAIL_TAG_IDX{1'b0}})
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_num_6, client_tag_released_num_6_wire, {RQ_AVAIL_TAG_IDX{1'b0}})
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_num_7, client_tag_released_num_7_wire, {RQ_AVAIL_TAG_IDX{1'b0}})

//   (*keep*)(*mark_debug*) reg [7:0] cpld_found_dw_d1;
//   (*keep*)(*mark_debug*) reg [9:0] rc_tdata_10btag;
//   (*keep*)(*mark_debug*) reg       m_axis_rc_tvalid_d1;
//   (*keep*)(*mark_debug*) reg       m_axis_rc_tdata_d1;
//   (*keep*)(*mark_debug*) reg       debug_client_tag_released_0;
//   (*keep*)(*mark_debug*) reg [9:0] debug_client_tag_released_num_0;

//   always @(posedge user_clk)
//   begin
//     cpld_found_dw_d1 <= cpld_found_dw;
//     rc_tdata_10btag  <= {m_axis_rc_tdata[47],m_axis_rc_tdata[31],m_axis_rc_tdata[71:64]};
//     m_axis_rc_tvalid_d1 <= m_axis_rc_tvalid;
//     m_axis_rc_tdata_d1  <= m_axis_rc_tdata;

//     if (m_axis_rc_tvalid_d1)
//     begin
//       debug_client_tag_released_0 <= cpld_found_dw_d1[0];
//       debug_client_tag_released_num_0 <= cfg_10b_tag_requester_enable ? rc_tdata_10btag : {2'b00,rc_tdata_10btag[7:0]}; 
//     end
//     else
//     begin
//       debug_client_tag_released_0 <= 0;
//     end
//   end


   //------------
   // Functions
   //------------

   // Function to check 4DW(Double Quad-Word) of incoming data
   function automatic f_rc_dqw_error_check;
      input          is_header_in;
      input [2:0]    is_end_in;
      input [127:0]  data_in;
      input [127:0]  exp_data_in;
      input [15:0]   be_in;

      if (is_header_in) begin // Header Check
         f_rc_dqw_error_check = (|((data_in[127:96] ^ exp_data_in[127:96]) &
                                   {{8{be_in[15]}}, {8{be_in[14]}}, {8{be_in[13]}}, {8{be_in[12]}}})) |  // Check DW[3] if BE is set
                                (data_in[15:12] != 4'd0) |                                               // Check Error Code
                                (is_end_in[2] & (|data_in[42:33]));                                      // Check EOP if Length is 0 or 1
      end else begin // Data Check
         f_rc_dqw_error_check = (|((data_in ^ exp_data_in) &
                                   {{8{be_in[15]}}, {8{be_in[14]}}, {8{be_in[13]}}, {8{be_in[12]}},      // Check DW[3] if BE is set
                                    {8{be_in[11]}}, {8{be_in[10]}}, {8{be_in[9] }}, {8{be_in[8] }},      // Check DW[2] if BE is set
                                    {8{be_in[7] }}, {8{be_in[6] }}, {8{be_in[5] }}, {8{be_in[4] }},      // Check DW[1] if BE is set
                                    {8{be_in[3] }}, {8{be_in[2] }}, {8{be_in[1] }}, {8{be_in[0] }}})) |  // Check DW[0] if BE is set
                                (is_end_in[2] & (~|be_in[15:0]));                                        // Check no EOP if no BE
      end
   endfunction

   // Function to check 4DW(Double Quad-Word) of incoming data in Address aligned mode
   //function automatic f_rc_dqw_error_check_addr_align;
   //   input          is_header_in;
   //   input          is_firstQW_in;
   //   input [2:0]    is_end_in;
   //   input [127:0]  data_in;
   //   input [127:0]  exp_data_in;
   //   input [15:0]   be_in;
   //   input [1:0]    addr_offset_in;

   //   if (is_header_in) begin // Header Check
   //      f_rc_dqw_error_check_addr_align =  (data_in[15:12] != 4'd0) ;                                   // Check Error Code
   //   end else if (is_firstQW_in) begin // Header Check
   //      case(addr_offset_in[1:0])
   //        2'b00: begin
   //                f_rc_dqw_error_check_addr_align = (|((data_in[127:0] ^ exp_data_in[127:0]) &
   //                                        {{8{be_in[15]}}, {8{be_in[14]}}, {8{be_in[13]}}, {8{be_in[12]}},      // Check DW[3] if BE is set
   //                                         {8{be_in[11]}}, {8{be_in[10]}}, {8{be_in[9] }}, {8{be_in[8] }},      // Check DW[2] if BE is set
   //                                         {8{be_in[7] }}, {8{be_in[6] }}, {8{be_in[5] }}, {8{be_in[4] }},      // Check DW[1] if BE is set
   //                                         {8{be_in[3] }}, {8{be_in[2] }}, {8{be_in[1] }}, {8{be_in[0] }}})) |  // Check DW[0] if BE is set
   //                                     (is_end_in[2] & (~|be_in[15:0]));                                        // Check no EOP if no BE
   //        end
   //        2'b01: begin
   //                f_rc_dqw_error_check_addr_align = (|((data_in[127:32] ^ exp_data_in[127:32]) &
   //                                        {{8{be_in[15]}}, {8{be_in[14]}}, {8{be_in[13]}}, {8{be_in[12]}},      // Check DW[3] if BE is set
   //                                         {8{be_in[11]}}, {8{be_in[10]}}, {8{be_in[9] }}, {8{be_in[8] }},      // Check DW[2] if BE is set
   //                                         {8{be_in[7] }}, {8{be_in[6] }}, {8{be_in[5] }}, {8{be_in[4] }}})) |  // Check DW[0] if BE is set
   //                                     (is_end_in[2] & (~|be_in[15:0]));                                        // Check no EOP if no BE
   //        end
   //        2'b10: begin
   //                f_rc_dqw_error_check_addr_align = (|((data_in[127:64] ^ exp_data_in[127:64]) &
   //                                        {{8{be_in[15]}}, {8{be_in[14]}}, {8{be_in[13]}}, {8{be_in[12]}},      // Check DW[3] if BE is set
   //                                         {8{be_in[11] }},{8{be_in[10]}}, {8{be_in[9] }}, {8{be_in[8] }}})) |  // Check DW[0] if BE is set
   //                                     (is_end_in[2] & (~|be_in[15:0]));                                        // Check no EOP if no BE
   //        end
   //        2'b11: begin
   //                f_rc_dqw_error_check_addr_align = (|((data_in[127:96] ^ exp_data_in[127:96]) &
   //                                        {{8{be_in[15]}}, {8{be_in[14]}}, {8{be_in[13]}}, {8{be_in[12] }}})) | // Check DW[3] if BE is set
   //                                     (is_end_in[2] & (~|be_in[15:0]));                                        // Check no EOP if no BE
   //        end
   //      endcase
   //   end else begin // Data Check
   //      f_rc_dqw_error_check_addr_align = (|((data_in ^ exp_data_in) &
   //                                {{8{be_in[15]}}, {8{be_in[14]}}, {8{be_in[13]}}, {8{be_in[12]}},      // Check DW[3] if BE is set
   //                                 {8{be_in[11]}}, {8{be_in[10]}}, {8{be_in[9] }}, {8{be_in[8] }},      // Check DW[2] if BE is set
   //                                 {8{be_in[7] }}, {8{be_in[6] }}, {8{be_in[5] }}, {8{be_in[4] }},      // Check DW[1] if BE is set
   //                                 {8{be_in[3] }}, {8{be_in[2] }}, {8{be_in[1] }}, {8{be_in[0] }}})) |  // Check DW[0] if BE is set
   //                             (is_end_in[2] & (~|be_in[15:0]));                                        // Check no EOP if no BE
   //   end
   //endfunction


   // Function to check parity of incoming data
   function automatic f_rc_dqw_parity_check;
      input          is_header_in;
      input [15:0]   parity_in;
      input [15:0]   exp_parity_in;
      input [15:0]   be_in;

      if (is_header_in) begin // Header Check
         f_rc_dqw_parity_check = ((|(parity_in[11:0] ^ exp_parity_in[11:0])) |                     // Check Header
                                  (|((parity_in[15:12] ^ exp_parity_in[15:12]) & be_in[15:12])));  // Check DW[3] if BE is set
      end else begin // Data Check
         f_rc_dqw_parity_check = (|((parity_in ^ exp_parity_in) & be_in));                         // Check DW[3:0] if BE is set
      end
   endfunction

endmodule
