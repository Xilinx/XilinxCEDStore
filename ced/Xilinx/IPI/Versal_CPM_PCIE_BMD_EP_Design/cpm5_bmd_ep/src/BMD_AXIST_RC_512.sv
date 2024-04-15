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
// File       : BMD_AXIST_RC_512.sv
// Version    : 1.0 
//-----------------------------------------------------------------------------

`include "pcie_app_versal_bmd.vh"
`timescale 1ps / 1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_RC_512 #(
   parameter         AXISTEN_IF_REQ_ALIGNMENT_MODE = 0,
   parameter         AXISTEN_IF_RC_STRADDLE        = 0,
   parameter         AXISTEN_IF_REQ_PARITY_CHECK   = 0,
   parameter         AXI4_CQ_TUSER_WIDTH           = 183,
   parameter         AXI4_CC_TUSER_WIDTH           = 81,
   parameter         AXI4_RQ_TUSER_WIDTH           = 137,
   parameter         AXI4_RC_TUSER_WIDTH           = 161,
   parameter         AXISTEN_IF_ENABLE_CLIENT_TAG  = 0,
   parameter         RQ_AVAIL_TAG_IDX              = 8,   
   parameter         TCQ                           = 1
) (
   // Clock and Reset
   input                            user_clk,
   input                            reset_n,
   input                            init_rst_i,

   // AXIST RC I/F
   (* mark_debug *) input                            m_axis_rc_tvalid,
   (* mark_debug *) input                            m_axis_rc_tlast,
   input        [160:0]             m_axis_rc_tuser,
   (* mark_debug *) input       [15:0]               m_axis_rc_tkeep,
   input        [511:0]             m_axis_rc_tdata,   
   output logic                     m_axis_rc_tready,

   // Client Tag
   output logic                     client_tag_released_0,
   output logic                     client_tag_released_1,
   output logic                     client_tag_released_2,
   output logic                     client_tag_released_3,

   output logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_0,
   output logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_1,
   output logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_2,
   output logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_3,

   // CPLD I/F to EP_MEM
   (* mark_debug *) input       [31:0]               cpld_data_i,
   (* mark_debug *) output logic [31:0]              cpld_found_o,
   (* mark_debug *) output logic [31:0]              cpld_data_size_o,
   (* mark_debug *) output logic                     cpld_data_err_o,
   (* mark_debug *) output logic                     cpld_parity_err_o
);
   `STRUCT_AXI_RC_IF

   logic [3:0]    dqw_is_header;
   logic [3:0]    dqw_is_first_qw0;
   (* mark_debug *)  logic [11:0]   dqw_is_end;
   (* mark_debug *) logic [3:0]    dqw_error_wire;
   logic [3:0]    dqw_parity_error_wire;
   logic          client_tag_released_0_wire;
   logic          client_tag_released_1_wire;
   logic          client_tag_released_2_wire;
   logic          client_tag_released_3_wire;
   logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_0_wire;
   logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_1_wire;
   logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_2_wire;
   logic [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_3_wire;
   s_axis_rc_tdata_512  m_axis_rc_tdata_in;
   s_axis_rc_tuser_512  m_axis_rc_tuser_in;

   assign m_axis_rc_tdata_in = m_axis_rc_tdata;
   assign m_axis_rc_tuser_in = m_axis_rc_tuser;

   // TODO: remove once debug is done
   (* mark_debug *) logic [3:0]    cpl_err_code = m_axis_rc_tdata_in.error_code;
   (* mark_debug *) logic [127:0]  cpl_data_lower_in = m_axis_rc_tdata[127:0];
   (* mark_debug *) logic [127:0]  cpl_data_upper_in = m_axis_rc_tdata[511:384];
   (* mark_debug *) logic [95:0]   cpl_tuser_in = m_axis_rc_tuser[95:0];
   (* mark_debug *) logic [3:0]    data_in_0 = m_axis_rc_tdata[15:12];
   (* mark_debug *) logic [3:0]    data_in_1 = m_axis_rc_tdata[143:140];
   (* mark_debug *) logic [3:0]    data_in_2 = m_axis_rc_tdata[271:268];
   (* mark_debug *) logic [3:0]    data_in_3 = m_axis_rc_tdata[399:396];
   (* mark_debug *) logic [15:0]    cpl_byte_en = m_axis_rc_tuser_in.byte_en;

   logic [3:0]    cpld_found_dw;
   logic [10:0]   cpld_data_size [3:0];
   logic [31:0]   cpld_found_wire;
   logic [31:0]   cpld_data_size_wire;
   logic          cpld_data_err_wire;
   logic          cpld_parity_err_wire;
   logic [63:0]   exp_parity;

   // Header or data
   assign dqw_is_header[0] =  m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 2'd0);
   assign dqw_is_header[1] = (m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 2'd1)) |
                             (m_axis_rc_tuser_in.is_sop[1] & (m_axis_rc_tuser_in.is_sop1_ptr == 2'd1));
   assign dqw_is_header[2] = (m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 2'd2)) |
                             (m_axis_rc_tuser_in.is_sop[1] & (m_axis_rc_tuser_in.is_sop1_ptr == 2'd2)) |
                             (m_axis_rc_tuser_in.is_sop[2] & (m_axis_rc_tuser_in.is_sop2_ptr == 2'd2));
   assign dqw_is_header[3] = (m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 2'd3)) |
                             (m_axis_rc_tuser_in.is_sop[1] & (m_axis_rc_tuser_in.is_sop1_ptr == 2'd3)) |
                             (m_axis_rc_tuser_in.is_sop[2] & (m_axis_rc_tuser_in.is_sop2_ptr == 2'd3)) |
                             (m_axis_rc_tuser_in.is_sop[3] & (m_axis_rc_tuser_in.is_sop3_ptr == 2'd3));

   assign dqw_is_first_qw0[0] =  'd0;
   assign dqw_is_first_qw0[1] =  (AXISTEN_IF_REQ_ALIGNMENT_MODE == "TRUE") ? m_axis_rc_tuser_in.is_sop[0] & (m_axis_rc_tuser_in.is_sop0_ptr == 2'd0) : 'd0;
   assign dqw_is_first_qw0[2] =  'd0;
   assign dqw_is_first_qw0[3] =  'd0;

   // End
generate
   if (AXISTEN_IF_RC_STRADDLE) begin: straddle_using_eop
      assign dqw_is_end[2:0]  =  (m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[3:2] == 2'd0))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0;
      assign dqw_is_end[5:3]  = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[3:2] == 2'd1))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[3:2] == 2'd1))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0);
      assign dqw_is_end[8:6]  = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[3:2] == 2'd2))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[3:2] == 2'd2))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[3:2] == 2'd2))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0);
      assign dqw_is_end[11:9] = ((m_axis_rc_tuser_in.is_eop[0] & (m_axis_rc_tuser_in.is_eop0_ptr[3:2] == 2'd3))? {1'b1, m_axis_rc_tuser_in.is_eop0_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[1] & (m_axis_rc_tuser_in.is_eop1_ptr[3:2] == 2'd3))? {1'b1, m_axis_rc_tuser_in.is_eop1_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[2] & (m_axis_rc_tuser_in.is_eop2_ptr[3:2] == 2'd3))? {1'b1, m_axis_rc_tuser_in.is_eop2_ptr[1:0]}: 3'd0) |
                                ((m_axis_rc_tuser_in.is_eop[3] & (m_axis_rc_tuser_in.is_eop3_ptr[3:2] == 2'd3))? {1'b1, m_axis_rc_tuser_in.is_eop3_ptr[1:0]}: 3'd0);
   end else begin: non_straddle_using_tlast_tkeep
      assign dqw_is_end[1:0]  = 2'b0;  // Not used by checker
      assign dqw_is_end[2]    = m_axis_rc_tlast & ~m_axis_rc_tkeep[4]  & (|m_axis_rc_tkeep[3:0]);
      assign dqw_is_end[4:3]  = 2'b0;  // Not used by checker
      assign dqw_is_end[5]    = m_axis_rc_tlast & ~m_axis_rc_tkeep[8]  & (|m_axis_rc_tkeep[7:4]);
      assign dqw_is_end[7:6]  = 2'b0;  // Not used by checker
      assign dqw_is_end[8]    = m_axis_rc_tlast & ~m_axis_rc_tkeep[12] & (|m_axis_rc_tkeep[11:8]);
      assign dqw_is_end[10:9] = 2'b0;  // Not used by checker
      assign dqw_is_end[11]   = m_axis_rc_tlast                        & (|m_axis_rc_tkeep[15:12]);
   end
endgenerate

genvar var_i;
generate
   for (var_i = 0; var_i < 64; var_i = var_i + 1) begin: rc_parity_generation
      // Generate expected parity for data
      assign exp_parity[var_i]   = ~(^m_axis_rc_tdata[8*(var_i+1)-1:8*var_i]);
   end
   for (var_i = 0; var_i < 4; var_i = var_i + 1) begin: dqw_generation
      // Check errors
      if(AXISTEN_IF_REQ_ALIGNMENT_MODE != "TRUE")
        assign dqw_error_wire[var_i]  = f_rc_dqw_error_check(dqw_is_header[var_i], dqw_is_end[var_i*3+:3], m_axis_rc_tdata[var_i*128+:128], {4{cpld_data_i}}, m_axis_rc_tuser_in.byte_en[var_i*16+:16]);
      else
        assign dqw_error_wire[var_i]  = f_rc_dqw_error_check_addr_align(dqw_is_header[var_i], dqw_is_first_qw0[var_i], dqw_is_end[var_i*3+:3], m_axis_rc_tdata[var_i*128+:128], {4{cpld_data_i}}, m_axis_rc_tuser_in.byte_en[var_i*16+:16], m_axis_rc_tdata_in.address[3:2]);

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
         cpld_found_wire      = cpld_found_o + {31'd0, cpld_found_dw[0]} + {31'd0, cpld_found_dw[1]} + {31'd0, cpld_found_dw[2]} + {31'd0, cpld_found_dw[3]};
         cpld_data_size_wire  = cpld_data_size_o + {21'd0, cpld_data_size[0]} + {21'd0, cpld_data_size[1]} + {21'd0, cpld_data_size[2]} + {21'd0, cpld_data_size[3]};
         cpld_data_err_wire   = (|dqw_error_wire) | cpld_data_err_o;
         cpld_parity_err_wire = AXISTEN_IF_REQ_PARITY_CHECK? (|dqw_parity_error_wire): 1'b0;
         client_tag_released_0_wire = cpld_found_dw[0] & AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_1_wire = cpld_found_dw[1] & AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_2_wire = cpld_found_dw[2] & AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_3_wire = cpld_found_dw[3] & AXISTEN_IF_ENABLE_CLIENT_TAG;
         client_tag_released_num_0_wire   = dqw_is_header[0]? m_axis_rc_tdata[  0+71:  0+64]: 8'b0;
         client_tag_released_num_1_wire   = dqw_is_header[1]? m_axis_rc_tdata[128+71:128+64]: 8'b0;
         client_tag_released_num_2_wire   = dqw_is_header[2]? m_axis_rc_tdata[256+71:256+64]: 8'b0;
         client_tag_released_num_3_wire   = dqw_is_header[3]? m_axis_rc_tdata[384+71:384+64]: 8'b0;
      end else begin
         cpld_found_wire      = cpld_found_o;
         cpld_data_size_wire  = cpld_data_size_o;
         cpld_data_err_wire   = cpld_data_err_o;
         cpld_parity_err_wire = 1'b0;
         client_tag_released_0_wire = 1'b0;
         client_tag_released_1_wire = 1'b0;
         client_tag_released_2_wire = 1'b0;
         client_tag_released_3_wire = 1'b0;
         client_tag_released_num_0_wire   = client_tag_released_num_0;
         client_tag_released_num_1_wire   = client_tag_released_num_1;
         client_tag_released_num_2_wire   = client_tag_released_num_2;
         client_tag_released_num_3_wire   = client_tag_released_num_3;
      end
   end

   `BMDREG(user_clk, reset_n, m_axis_rc_tready, 1'b1, 1'b0)          // Deassert tready while reset  // ready modulation later 09.03.2015
   `BMDREG(user_clk, (reset_n & ~init_rst_i), cpld_found_o, cpld_found_wire, 32'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), cpld_data_size_o, cpld_data_size_wire, 32'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), cpld_data_err_o, cpld_data_err_wire, 1'b0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), cpld_parity_err_o, cpld_parity_err_wire, 1'b0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_0, client_tag_released_0_wire, 1'b0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_1, client_tag_released_1_wire, 1'b0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_2, client_tag_released_2_wire, 1'b0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_3, client_tag_released_3_wire, 1'b0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_num_0, client_tag_released_num_0_wire, 8'b0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_num_1, client_tag_released_num_1_wire, 8'b0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_num_2, client_tag_released_num_2_wire, 8'b0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_released_num_3, client_tag_released_num_3_wire, 8'b0)

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
   function automatic f_rc_dqw_error_check_addr_align;
      input          is_header_in;
      input          is_firstQW_in;
      input [2:0]    is_end_in;
      input [127:0]  data_in;
      input [127:0]  exp_data_in;
      input [15:0]   be_in;
      input [1:0]    addr_offset_in;

      if (is_header_in) begin // Header Check
         f_rc_dqw_error_check_addr_align =  (data_in[15:12] != 4'd0) ;                                   // Check Error Code
      end else if (is_firstQW_in) begin // Header Check
         case(addr_offset_in[1:0])
           2'b00: begin
                   f_rc_dqw_error_check_addr_align = (|((data_in[127:0] ^ exp_data_in[127:0]) &
                                           {{8{be_in[15]}}, {8{be_in[14]}}, {8{be_in[13]}}, {8{be_in[12]}},      // Check DW[3] if BE is set
                                            {8{be_in[11]}}, {8{be_in[10]}}, {8{be_in[9] }}, {8{be_in[8] }},      // Check DW[2] if BE is set
                                            {8{be_in[7] }}, {8{be_in[6] }}, {8{be_in[5] }}, {8{be_in[4] }},      // Check DW[1] if BE is set
                                            {8{be_in[3] }}, {8{be_in[2] }}, {8{be_in[1] }}, {8{be_in[0] }}})) |  // Check DW[0] if BE is set
                                        (is_end_in[2] & (~|be_in[15:0]));                                        // Check no EOP if no BE
           end
           2'b01: begin
                   f_rc_dqw_error_check_addr_align = (|((data_in[127:32] ^ exp_data_in[127:32]) &
                                           {{8{be_in[15]}}, {8{be_in[14]}}, {8{be_in[13]}}, {8{be_in[12]}},      // Check DW[3] if BE is set
                                            {8{be_in[11]}}, {8{be_in[10]}}, {8{be_in[9] }}, {8{be_in[8] }},      // Check DW[2] if BE is set
                                            {8{be_in[7] }}, {8{be_in[6] }}, {8{be_in[5] }}, {8{be_in[4] }}})) |  // Check DW[0] if BE is set
                                        (is_end_in[2] & (~|be_in[15:0]));                                        // Check no EOP if no BE
           end
           2'b10: begin
                   f_rc_dqw_error_check_addr_align = (|((data_in[127:64] ^ exp_data_in[127:64]) &
                                           {{8{be_in[15]}}, {8{be_in[14]}}, {8{be_in[13]}}, {8{be_in[12]}},      // Check DW[3] if BE is set
                                            {8{be_in[11] }},{8{be_in[10]}}, {8{be_in[9] }}, {8{be_in[8] }}})) |  // Check DW[0] if BE is set
                                        (is_end_in[2] & (~|be_in[15:0]));                                        // Check no EOP if no BE
           end
           2'b11: begin
                   f_rc_dqw_error_check_addr_align = (|((data_in[127:96] ^ exp_data_in[127:96]) &
                                           {{8{be_in[15]}}, {8{be_in[14]}}, {8{be_in[13]}}, {8{be_in[12] }}})) | // Check DW[3] if BE is set
                                        (is_end_in[2] & (~|be_in[15:0]));                                        // Check no EOP if no BE
           end
         endcase
      end else begin // Data Check
         f_rc_dqw_error_check_addr_align = (|((data_in ^ exp_data_in) &
                                   {{8{be_in[15]}}, {8{be_in[14]}}, {8{be_in[13]}}, {8{be_in[12]}},      // Check DW[3] if BE is set
                                    {8{be_in[11]}}, {8{be_in[10]}}, {8{be_in[9] }}, {8{be_in[8] }},      // Check DW[2] if BE is set
                                    {8{be_in[7] }}, {8{be_in[6] }}, {8{be_in[5] }}, {8{be_in[4] }},      // Check DW[1] if BE is set
                                    {8{be_in[3] }}, {8{be_in[2] }}, {8{be_in[1] }}, {8{be_in[0] }}})) |  // Check DW[0] if BE is set
                                (is_end_in[2] & (~|be_in[15:0]));                                        // Check no EOP if no BE
      end
   endfunction


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
