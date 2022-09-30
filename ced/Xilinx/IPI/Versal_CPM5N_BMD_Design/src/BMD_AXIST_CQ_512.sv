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
module BMD_AXIST_CQ_512 #(
   parameter         AXISTEN_IF_CMP_ALIGNMENT_MODE = 0,
   parameter         AXISTEN_IF_CQ_STRADDLE        = 0,
   parameter         AXISTEN_IF_CMP_PARITY_CHECK   = 0,
   parameter         AXI4_CQ_TUSER_WIDTH           = 183,
   parameter         AXI4_CC_TUSER_WIDTH           = 81,
   parameter         AXI4_RQ_TUSER_WIDTH           = 137,
   parameter         AXI4_RC_TUSER_WIDTH           = 161,
   parameter         C_DATA_WIDTH                  = 512,
   parameter         KEEP_WIDTH                    = C_DATA_WIDTH / 32,
   parameter         TCQ                           = 1
) (
   // Clock and Reset
   input                            user_clk,
   input                            reset_n,

   input                            m_axis_cq_tvalid,
   input                            m_axis_cq_tlast,
   input        [182:0]             m_axis_cq_tuser,
   input        [KEEP_WIDTH-1:0]    m_axis_cq_tkeep,
   input        [511:0]             m_axis_cq_tdata,
   output logic                     m_axis_cq_tready,
   output logic                     pcie_cq_np_req,

   output logic                     req_compl,
   output logic                     req_compl_wd,
   output logic                     req_compl_ur,
   input                            compl_done,

   output logic [2:0]               req_tc,             // Memory Read TC
   output logic [2:0]               req_attr,           // Memory Read Attribute
   output logic [10:0]              req_len,            // Memory Read Length
   output logic [15:0]              req_rid,            // Memory Read Requestor ID { 8'b0 (Bus no),
                                                        //                            3'b0 (Dev no),
                                                        //                            5'b0 (Func no)}
   output logic [7:0]               req_tag,            // Memory Read Tag
   output logic [7:0]               req_be,             // Memory Read Byte Enables
   output logic [12:0]              req_addr,           // Memory Read Address
   output logic [1:0]               req_at,             // Address Translation
 
   output logic [63:0]              req_des_qword0,     // DWord0 and Dword1 of descriptor of the request
   output logic [63:0]              req_des_qword1,     // DWord2 and Dword3 of descriptor of the request
   output logic                     req_des_tph_present,// TPH Present in the request
   output logic [1:0]               req_des_tph_type,   // If TPH Present then TPH type
   output logic [7:0]               req_des_tph_st_tag, // TPH Steering tag of the request
 
   output logic                     req_mem_lock,
   output logic                     req_mem,
 
   output logic [10:0]              wr_addr,            // Memory Write Address
   output logic [7:0]               wr_be,              // Memory Write Byte Enable
   output logic [63:0]              wr_data,            // Memory Write Data
   output logic                     wr_en,              // Memory Write Enable
   output logic                     payload_len,        // Transaction Payload Length
   input                            wr_busy,            // Memory Write Busy
   
   output logic                     req_parity_err      // Parity error
);
   `STRUCT_AXI_CQ_IF_512

   logic          sop, sop_wire;
   logic [7:0]    state;
   logic [2:0]    data_start_loc;
   logic [3:0]    trn_type;
   logic          io_bar_hit_n;
   logic          mem64_bar_hit_n;
   logic          erom_bar_hit_n;
   logic          mem32_bar_hit_n;
   logic [1:0]    region_select;
   s_axis_cq_tdata_512  m_axis_cq_tdata_in;
   s_axis_cq_tuser_512  m_axis_cq_tuser_in;
   logic [63:0]   exp_parity;
   logic          parity_error_wire;

   reg [C_DATA_WIDTH-1:0]        m_axis_cq_tdata_q;
   reg [AXI4_CQ_TUSER_WIDTH-1:0] m_axis_cq_tuser_q;
   reg                           m_axis_cq_tkeep_q;
   reg                           m_axis_cq_tvalid_q;

   assign m_axis_cq_tdata_in = m_axis_cq_tdata;
   assign m_axis_cq_tuser_in = m_axis_cq_tuser;

   // Generate a signal that indicates if we are currently receiving a packet.
   // This value is one clock cycle delayed from what is actually on the AXIS
   // data bus.
   always_comb begin
      if (m_axis_cq_tvalid & m_axis_cq_tready) begin
         sop_wire = m_axis_cq_tlast;
      end else begin
         sop_wire = sop;
      end
   end
   `BMDREG(user_clk, reset_n, sop, sop_wire, 'd1)

   always @(posedge user_clk)
   begin
     if(!reset_n)
     begin
       m_axis_cq_tdata_q    <= #TCQ {C_DATA_WIDTH{1'b0}};
       m_axis_cq_tuser_q    <= #TCQ {AXI4_CQ_TUSER_WIDTH{1'b0}};
       m_axis_cq_tkeep_q    <= #TCQ {KEEP_WIDTH{1'd0}};
       m_axis_cq_tvalid_q   <= #TCQ 1'b0;
     end
     else if(m_axis_cq_tvalid)
     begin
       m_axis_cq_tdata_q    <= #TCQ m_axis_cq_tdata;
       m_axis_cq_tuser_q    <= #TCQ m_axis_cq_tuser;
       m_axis_cq_tkeep_q    <= #TCQ m_axis_cq_tkeep;
       m_axis_cq_tvalid_q   <= #TCQ m_axis_cq_tvalid;
     end
   end
 

   // TODO: Legacy code, need to review
   localparam BMD_AXIST_RX_MEM_RD_FMT_TYPE    = 4'b0000;    // Memory Read
   localparam BMD_AXIST_RX_MEM_WR_FMT_TYPE    = 4'b0001;    // Memory Write
   localparam BMD_AXIST_RX_IO_RD_FMT_TYPE     = 4'b0010;    // IO Read
   localparam BMD_AXIST_RX_IO_WR_FMT_TYPE     = 4'b0011;    // IO Write
   localparam BMD_AXIST_RX_ATOP_FAA_FMT_TYPE  = 4'b0100;    // Fetch and ADD
   localparam BMD_AXIST_RX_ATOP_UCS_FMT_TYPE  = 4'b0101;    // Unconditional SWAP
   localparam BMD_AXIST_RX_ATOP_CAS_FMT_TYPE  = 4'b0110;    // Compare and SWAP
   localparam BMD_AXIST_RX_MEM_LK_RD_FMT_TYPE = 4'b0111;    // Locked Read Request
   localparam BMD_AXIST_RX_MSG_FMT_TYPE       = 4'b1100;    // MSG Transaction apart from Vendor Defined and ATS
   localparam BMD_AXIST_RX_MSG_VD_FMT_TYPE    = 4'b1101;    // MSG Transaction apart from Vendor Defined and ATS
   localparam BMD_AXIST_RX_MSG_ATS_FMT_TYPE   = 4'b1110;    // MSG Transaction apart from Vendor Defined and ATS

   localparam BMD_AXIST_RX_RST_STATE          = 8'b00000000;
   localparam BMD_AXIST_RX_WAIT_STATE         = 8'b00000001;
   localparam BMD_AXIST_RX_DATA               = 8'b00000011;
   localparam BMD_AXIST_RX_DATA2              = 8'b00000100;

   // Parity Check
genvar var_i;
generate
   for (var_i = 0; var_i < 64; var_i = var_i + 1) begin: cq_parity_generation
      // Generate expected parity for data
      assign exp_parity[var_i]   = ~(^m_axis_cq_tdata_in[8*(var_i+1)-1:8*var_i]);
   end
endgenerate

   always_comb begin
      if (m_axis_cq_tvalid & m_axis_cq_tready & AXISTEN_IF_CMP_PARITY_CHECK) begin  // 512b I/F only has 1-beat packet
         parity_error_wire = ((|(m_axis_cq_tuser_in.parity[15:0] ^ exp_parity[15:0])) |                                    // Check Header
                              (|((m_axis_cq_tuser_in.parity[63:16] ^ exp_parity[63:16]) & m_axis_cq_tuser_in.byte_en[63:16])));  // Check DW[3] if BE is set
      end else begin
         parity_error_wire = 1'b0;
      end
   end
   `BMDREG(user_clk, reset_n, req_parity_err, parity_error_wire, 1'b0)

   always_ff @(posedge user_clk) begin
     if(!reset_n) begin
       m_axis_cq_tready    <= #TCQ 1'b0;

       req_compl           <= #TCQ 1'b0;
       req_compl_wd        <= #TCQ 1'b0;
       req_compl_ur        <= #TCQ 1'b0;

       req_tc              <= #TCQ 3'b0;
       req_attr            <= #TCQ 3'b0;
       req_len             <= #TCQ 11'b0;
       req_rid             <= #TCQ 16'b0;
       req_tag             <= #TCQ 8'b0;
       req_be              <= #TCQ 8'b0;
       req_addr            <= #TCQ 13'b0;
       req_at              <= #TCQ 2'b0;

       wr_be               <= #TCQ 8'b0;
       wr_addr             <= #TCQ 11'b0;
       wr_data             <= #TCQ 64'h0;
       wr_en               <= #TCQ 1'b0;
       payload_len         <= #TCQ 1'b0;
       data_start_loc      <= #TCQ 3'b0;

       state               <= #TCQ BMD_AXIST_RX_RST_STATE;
       trn_type            <= #TCQ 4'b0;

       req_des_qword0      <= #TCQ 64'b0;
       req_des_qword1      <= #TCQ 64'b0;
       req_des_tph_present <= #TCQ 1'b0;
       req_des_tph_type    <= #TCQ 2'b0;
       req_des_tph_st_tag  <= #TCQ 8'b0;

       req_mem_lock        <= #TCQ 1'b0;
       req_mem             <= #TCQ 1'b0;
       pcie_cq_np_req      <= #TCQ 1'b1;

     end else begin //{

       wr_en               <= #TCQ 1'b0;
       req_compl           <= #TCQ 1'b0;
//       pcie_cq_np_req      <= #TCQ 1'b0; // Drive to 1 to receive PIO reads
       pcie_cq_np_req      <= #TCQ 1'b1;

       case (state) //{

         BMD_AXIST_RX_RST_STATE : begin //{

           m_axis_cq_tready <= #TCQ 1'b1;
           //req_compl_wd     <= #TCQ 1'b1;

           if (m_axis_cq_tvalid & sop) begin //sop_if //{

             case( m_axis_cq_tdata_in[78:75] ) // Req_Type_fsm //{

               BMD_AXIST_RX_MEM_RD_FMT_TYPE : begin //{

                 trn_type         <= #TCQ m_axis_cq_tdata_in[78:75];
                 req_len          <= #TCQ m_axis_cq_tdata_in[74:64];
                 m_axis_cq_tready <= #TCQ 1'b0;
                 req_mem          <= #TCQ 1'b1;
                 state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                 req_be           <= #TCQ m_axis_cq_tuser_in[7:0];
                 req_des_qword0      <= #TCQ m_axis_cq_tdata_in[63:0];
                 req_des_qword1      <= #TCQ m_axis_cq_tdata_in[127:64];
                 pcie_cq_np_req      <= #TCQ 1'b1;

                 if((m_axis_cq_tdata_in[74:64] == 11'h001) || (m_axis_cq_tdata_in[74:64] == 11'h002))
                 begin //{
                   req_compl        <= #TCQ 1'b0;
                   req_compl_wd     <= #TCQ 1'b1;
                   req_tc           <= #TCQ m_axis_cq_tdata_in[123:121];
                   req_attr         <= #TCQ m_axis_cq_tdata_in[126:124];
                   req_rid          <= #TCQ m_axis_cq_tdata_in[95:80];
                   req_tag          <= #TCQ m_axis_cq_tdata_in[103:96];
                   req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata_in[10:2], 2'b00};
                   req_at           <= #TCQ m_axis_cq_tdata_in[1:0];
                   payload_len    <=#TCQ m_axis_cq_tdata_in[65];
                 end //}
                 else begin //{
                   req_compl        <= #TCQ 1'b0;
                   req_compl_wd     <= #TCQ 1'b0;
                   req_compl_ur     <= #TCQ 1'b1;
                   req_des_tph_present <= #TCQ m_axis_cq_tuser_in[42];
                   req_des_tph_type    <= #TCQ m_axis_cq_tuser_in[44:43];
                   req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser_in[52:45];
                 end //}

               end  // BMD_AXIST_RX_MEM_RD_FMT_TYPE //}


               BMD_AXIST_RX_MEM_WR_FMT_TYPE : begin //{

                 trn_type         <= #TCQ m_axis_cq_tdata_in[78:75];
                 req_len          <= #TCQ m_axis_cq_tdata_in[74:64];
                 req_mem          <= #TCQ 1'b0;
                 if(m_axis_cq_tdata_in[74:64] == 11'h002) // 2DWord Payload
                   payload_len    <=#TCQ 1'b1;
                 else
                   payload_len   <=#TCQ 1'b0;

                 if(AXISTEN_IF_CMP_ALIGNMENT_MODE == 2'b00) begin //{ // DWord Aligned Mode
                   if(m_axis_cq_tdata_in[74:64] == 11'h002) begin //{ // 2DWord Payload
                     wr_data        <= #TCQ m_axis_cq_tdata_in[191:128];
                   end //}
                   else if (m_axis_cq_tdata_in[74:64] == 11'h001) begin //{ // 1DW Payload
                     wr_data       <= #TCQ { 32'b0, m_axis_cq_tdata_in[159:128]};
                   end //}
                 end //}

                 if((m_axis_cq_tdata_in[74:64] == 11'h001) || (m_axis_cq_tdata_in[74:64] == 11'h002))
                 begin //{

                   if(AXISTEN_IF_CMP_ALIGNMENT_MODE == 2'b00) begin //{ // DWord Aligned Mode
                     state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                     wr_be            <= #TCQ m_axis_cq_tuser_in[7:0];
                     wr_en            <= #TCQ 1'b1;
                     wr_addr          <= #TCQ {region_select[1:0],m_axis_cq_tdata_in[10:2]};
                     req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata_in[10:2], 2'b00};
                     m_axis_cq_tready <= #TCQ 1'b0;
                   end // DWord Aligned Mode //}
                   else begin // Address Aligned Mode //{
                     state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                     wr_en            <= #TCQ 1'b1;
                     wr_addr          <= #TCQ {region_select[1:0],m_axis_cq_tdata_in[10:2]};
                     req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata_in[10:2], 2'b00};
                     m_axis_cq_tready <= #TCQ 1'b0;
                     data_start_loc   <= #TCQ (AXISTEN_IF_CMP_ALIGNMENT_MODE  != 2'b00) ? {m_axis_cq_tdata[4:2]} : 3'b0;
                     case (m_axis_cq_tdata[3:2]) //{
                       2'b00 : begin //{
                         wr_data[31:0]    <= #TCQ m_axis_cq_tdata[159:128] ;
                         wr_data[63:32]   <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tdata[191:160] : 32'h0;
                         wr_be            <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tuser[39:32] : { 4'h0, m_axis_cq_tuser[35:32]};
                       end //}
                       2'b01 : begin //{
                         wr_data[31:0]    <= #TCQ m_axis_cq_tdata[191:160] ;
                         wr_data[63:32]   <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tdata[223:192] : 32'h0;
                         wr_be            <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tuser[42:36] : { 4'h0, m_axis_cq_tuser[39:36]};
                       end //}
                       2'b10 : begin //{
                         wr_data[31:0]    <= #TCQ m_axis_cq_tdata[223:192] ;
                         wr_data[63:32]   <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tdata[255:224] : 32'h0;
                         wr_be            <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tuser[47:40] : { 4'h0, m_axis_cq_tuser[43:40]};
                       end //}
                       2'b11 : begin //{
                         wr_data[31:0]    <= #TCQ m_axis_cq_tdata[255:224];
                         wr_data[63:32]   <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tdata[287:256] : 32'h0;
                         wr_be            <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tuser[51:44] : { 4'h0, m_axis_cq_tuser[47:44]};
                       end //}
                       default : begin //{
                         state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                       end //}
                     endcase //}

                   end //}

                 end //}
                 else begin // Payload > 2DWORD //{
                   state            <= #TCQ BMD_AXIST_RX_RST_STATE;
                 end //}
               end // BMD_AXIST_RX_MEM_WR_FMT_TYPE //}


               BMD_AXIST_RX_IO_RD_FMT_TYPE : begin //{

                 trn_type         <= #TCQ m_axis_cq_tdata_in[78:75];
                 req_len          <= #TCQ m_axis_cq_tdata_in[74:64];
                 m_axis_cq_tready <= #TCQ 1'b0;
                 req_mem          <= #TCQ 1'b0;
                 state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                 req_be           <= #TCQ m_axis_cq_tuser_in[7:0];
                 req_des_qword0      <= #TCQ m_axis_cq_tdata_in[63:0];
                 req_des_qword1      <= #TCQ m_axis_cq_tdata_in[127:64];
                 pcie_cq_np_req      <= #TCQ 1'b1;

                 if((m_axis_cq_tdata_in[74:64] == 11'h001) || (m_axis_cq_tdata_in[74:64] == 11'h002))
                 begin //{
                   req_compl        <= #TCQ 1'b0;
                   req_compl_wd     <= #TCQ 1'b1;
                   req_tc           <= #TCQ m_axis_cq_tdata_in[123:121];
                   req_attr         <= #TCQ m_axis_cq_tdata_in[126:124];
                   req_rid          <= #TCQ m_axis_cq_tdata_in[95:80];
                   req_tag          <= #TCQ m_axis_cq_tdata_in[103:96];
                   req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata_in[10:2], 2'b00};
                   req_at           <= #TCQ m_axis_cq_tdata_in[1:0];
                   payload_len    <=#TCQ m_axis_cq_tdata_in[65];
                 end //}
                 else begin //{
                   req_compl        <= #TCQ 1'b0;
                   req_compl_wd     <= #TCQ 1'b0;
                   req_compl_ur     <= #TCQ 1'b1;
                   req_des_tph_present <= #TCQ m_axis_cq_tuser_in[42];
                   req_des_tph_type    <= #TCQ m_axis_cq_tuser_in[44:43];
                   req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser_in[52:45];
                 end //}

               end //BMD_AXIST_RX_IO_RD_FMT_TYPE //}


               BMD_AXIST_RX_IO_WR_FMT_TYPE : begin //{

                 trn_type         <= #TCQ m_axis_cq_tdata_in[78:75];
                 req_len          <= #TCQ m_axis_cq_tdata_in[74:64];
                 req_mem          <= #TCQ 1'b0;
                 state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                 req_be           <= #TCQ m_axis_cq_tuser_in[7:0];

                 if((m_axis_cq_tdata_in[74:64] == 11'h001) || (m_axis_cq_tdata_in[74:64] == 11'h002))
                 begin //{
                   req_compl        <= #TCQ 1'b1;
                   req_compl_wd     <= #TCQ 1'b0;
                   req_tc           <= #TCQ m_axis_cq_tdata_in[123:121];
                   req_attr         <= #TCQ m_axis_cq_tdata_in[126:124];
                   req_rid          <= #TCQ m_axis_cq_tdata_in[95:80];
                   req_tag          <= #TCQ m_axis_cq_tdata_in[103:96];
                   req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata_in[10:2], 2'b00};
                   req_at           <= #TCQ m_axis_cq_tdata_in[1:0];
                   req_des_qword0      <= #TCQ m_axis_cq_tdata_in[63:0];
                   req_des_qword1      <= #TCQ m_axis_cq_tdata_in[127:64];
                   payload_len   <=#TCQ m_axis_cq_tdata_in[65];
                   if(AXISTEN_IF_CMP_ALIGNMENT_MODE == 2'b00) begin // DWord Aligned Mode //{
                     state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                     wr_be            <= #TCQ m_axis_cq_tuser_in[7:0];
                     wr_en            <= #TCQ 1'b1;
                     wr_addr          <= #TCQ {region_select[1:0],m_axis_cq_tdata_in[10:2]};
                     m_axis_cq_tready <= #TCQ 1'b0;
                     if(m_axis_cq_tdata_in[74:64] == 11'h002) begin // 2DWord Payload //{
                       wr_data        <= #TCQ m_axis_cq_tdata_in[191:128];
                     end //}
                     else if (m_axis_cq_tdata_in[74:64] == 11'h001) begin // 1DW Payload //{
                       wr_data       <= #TCQ { 32'b0, m_axis_cq_tdata_in[159:128]};
                     end //}
                   end //} DWord Aligned Mode
                   else begin // Address Aligned Mode //{
                     state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                     wr_en            <= #TCQ 1'b1;
                     wr_addr          <= #TCQ {region_select[1:0],m_axis_cq_tdata_in[10:2]};
                     req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata_in[10:2], 2'b00};
                     m_axis_cq_tready <= #TCQ 1'b0;
                     data_start_loc   <= #TCQ (AXISTEN_IF_CMP_ALIGNMENT_MODE  != 2'b00) ? {m_axis_cq_tdata[4:2]} : 3'b0;
                     case (m_axis_cq_tdata[3:2]) //{
                       2'b00 : begin //{
                         wr_data[31:0]    <= #TCQ m_axis_cq_tdata[159:128] ;
                         wr_data[63:32]   <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tdata[191:160] : 32'h0;
                         wr_be            <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tuser[39:32] : { 4'h0, m_axis_cq_tuser[35:32]};
                       end //}
                       2'b01 : begin //{
                         wr_data[31:0]    <= #TCQ m_axis_cq_tdata[191:160] ;
                         wr_data[63:32]   <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tdata[223:192] : 32'h0;
                         wr_be            <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tuser[42:36] : { 4'h0, m_axis_cq_tuser[39:36]};
                       end //}
                       2'b10 : begin //{
                         wr_data[31:0]    <= #TCQ m_axis_cq_tdata[223:192] ;
                         wr_data[63:32]   <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tdata[255:224] : 32'h0;
                         wr_be            <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tuser[47:40] : { 4'h0, m_axis_cq_tuser[43:40]};
                       end //}
                       2'b11 : begin //{
                         wr_data[31:0]    <= #TCQ m_axis_cq_tdata[255:224];
                         wr_data[63:32]   <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tdata[287:256] : 32'h0;
                         wr_be            <= #TCQ (m_axis_cq_tdata_in[74:64] == 11'h002) ? m_axis_cq_tuser[51:44] : { 4'h0, m_axis_cq_tuser[47:44]};
                       end //}
                       default : begin //{
                         state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                       end //}
                     endcase //}


                   end //}
                 end //}
                 else begin // Payload > 2DWORDs //{
                   req_compl        <= #TCQ 1'b0;
                   req_compl_wd     <= #TCQ 1'b0;
                   req_compl_ur     <= #TCQ 1'b1;
                   req_des_tph_present <= #TCQ m_axis_cq_tuser_in[42];
                   req_des_tph_type    <= #TCQ m_axis_cq_tuser_in[44:43];
                   req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser_in[52:45];
                   state            <= #TCQ BMD_AXIST_RX_RST_STATE;
                 end //}

               end // BMD_AXIST_RX_IO_WR_FMT_TYPE //}


               BMD_AXIST_RX_ATOP_FAA_FMT_TYPE, BMD_AXIST_RX_ATOP_UCS_FMT_TYPE, BMD_AXIST_RX_ATOP_CAS_FMT_TYPE : begin //{

                 trn_type         <= #TCQ m_axis_cq_tdata_in[78:75];
                 req_len          <= #TCQ m_axis_cq_tdata_in[74:64];
                 m_axis_cq_tready <= #TCQ 1'b0;
                 req_mem          <= #TCQ 1'b0;
                 state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                 req_be           <= #TCQ m_axis_cq_tuser_in[7:0];
                 req_des_qword0      <= #TCQ m_axis_cq_tdata_in[63:0];
                 req_des_qword1      <= #TCQ m_axis_cq_tdata_in[127:64];

                 if((m_axis_cq_tdata_in[74:64] == 11'h001) || (m_axis_cq_tdata_in[74:64] == 11'h002))
                 begin //{
                   req_compl        <= #TCQ 1'b1;
                   req_compl_wd     <= #TCQ 1'b0;
                   req_tc           <= #TCQ m_axis_cq_tdata_in[123:121];
                   req_attr         <= #TCQ m_axis_cq_tdata_in[126:124];
                   req_rid          <= #TCQ m_axis_cq_tdata_in[95:80];
                   req_tag          <= #TCQ m_axis_cq_tdata_in[103:96];
                 end //}
                 else begin //{
                   req_compl        <= #TCQ 1'b0;
                   req_compl_wd     <= #TCQ 1'b0;
                   req_compl_ur     <= #TCQ 1'b1;
                   req_des_tph_present <= #TCQ m_axis_cq_tuser_in[42];
                   req_des_tph_type    <= #TCQ m_axis_cq_tuser_in[44:43];
                   req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser_in[52:45];
                 end //}

               end // BMD_AXIST_RX_ATOP_FAA_FMT_TYPE, BMD_AXIST_RX_ATOP_UCS_FMT_TYPE, BMD_AXIST_RX_ATOP_CAS_FMT_TYPE //}


               BMD_AXIST_RX_MEM_LK_RD_FMT_TYPE : begin //{

                 trn_type         <= #TCQ m_axis_cq_tdata_in[78:75];
                 req_len          <= #TCQ m_axis_cq_tdata_in[74:64];
                 m_axis_cq_tready <= #TCQ 1'b0;
                 state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                 req_be           <= #TCQ m_axis_cq_tuser_in[7:0];
                 req_des_qword0      <= #TCQ m_axis_cq_tdata_in[63:0];
                 req_des_qword1      <= #TCQ m_axis_cq_tdata_in[127:64];
                 pcie_cq_np_req      <= #TCQ 1'b1;

                 if((m_axis_cq_tdata_in[74:64] == 11'h001) || (m_axis_cq_tdata_in[74:64] == 11'h002))
                 begin //{
                   req_compl        <= #TCQ 1'b1;
                   req_compl_wd     <= #TCQ 1'b1;
                   req_tc           <= #TCQ m_axis_cq_tdata_in[123:121];
                   req_attr         <= #TCQ m_axis_cq_tdata_in[126:124];
                   req_rid          <= #TCQ m_axis_cq_tdata_in[95:80];
                   req_tag          <= #TCQ m_axis_cq_tdata_in[103:96];
                   req_mem_lock     <= #TCQ 1'b1;
                   req_addr         <= #TCQ {region_select[1:0],m_axis_cq_tdata_in[10:2], 2'b00};
                   req_at           <= #TCQ m_axis_cq_tdata_in[1:0];
                   payload_len   <=#TCQ m_axis_cq_tdata_in[65];
                 end //}
                 else begin //{
                   req_compl        <= #TCQ 1'b1;
                   req_compl_wd     <= #TCQ 1'b0;
                   req_compl_ur     <= #TCQ 1'b1;
                   req_des_tph_present <= #TCQ m_axis_cq_tuser_in[42];
                   req_des_tph_type    <= #TCQ m_axis_cq_tuser_in[44:43];
                   req_des_tph_st_tag  <= #TCQ m_axis_cq_tuser_in[52:45];
                 end //}


               end //BMD_AXIST_RX_MEM_LK_RD_FMT_TYPE //}


               BMD_AXIST_RX_MSG_FMT_TYPE : begin //{

                 trn_type             <= #TCQ m_axis_cq_tdata_in[78:75];
                 req_len              <= #TCQ m_axis_cq_tdata_in[74:64];
                 req_mem              <= #TCQ 1'b0;
                 m_axis_cq_tready     <= #TCQ 1'b0;
                 req_tc               <= #TCQ m_axis_cq_tdata_in[123:121];
                 req_attr             <= #TCQ m_axis_cq_tdata_in[126:124];
                 req_at               <= #TCQ m_axis_cq_tdata_in[1:0];
                 req_rid              <= #TCQ m_axis_cq_tdata_in[95:80];
                 req_tag              <= #TCQ m_axis_cq_tdata_in[103:96];
                 req_be               <= #TCQ m_axis_cq_tuser_in[7:0];
                 state                <= #TCQ BMD_AXIST_RX_RST_STATE;

               end // BMD_AXIST_RX_MSG_FMT_TYPE //}


               BMD_AXIST_RX_MSG_VD_FMT_TYPE : begin //{

                 trn_type             <= #TCQ m_axis_cq_tdata_in[78:75];
                 req_len              <= #TCQ m_axis_cq_tdata_in[74:64];
                 m_axis_cq_tready     <= #TCQ 1'b0;
                 req_mem              <= #TCQ 1'b0;
                 req_tc               <= #TCQ m_axis_cq_tdata_in[123:121];
                 req_attr             <= #TCQ m_axis_cq_tdata_in[126:124];
                 req_rid              <= #TCQ m_axis_cq_tdata_in[95:80];
                 req_tag              <= #TCQ m_axis_cq_tdata_in[103:96];
                 req_be               <= #TCQ m_axis_cq_tuser_in[7:0];
                 req_at               <= #TCQ m_axis_cq_tdata_in[1:0];
                 state                <= #TCQ BMD_AXIST_RX_RST_STATE;

               end // BMD_AXIST_RX_MSG_VD_FMT_TYPE //}


               BMD_AXIST_RX_MSG_ATS_FMT_TYPE : begin //{

                 trn_type             <= #TCQ m_axis_cq_tdata_in[78:75];
                 req_len              <= #TCQ m_axis_cq_tdata_in[74:64];
                 m_axis_cq_tready     <= #TCQ 1'b0;
                 req_mem              <= #TCQ 1'b0;
                 req_tc               <= #TCQ m_axis_cq_tdata_in[123:121];
                 req_attr             <= #TCQ m_axis_cq_tdata_in[126:124];
                 req_at               <= #TCQ m_axis_cq_tdata_in[1:0];
                 req_rid              <= #TCQ m_axis_cq_tdata_in[95:80];
                 req_tag              <= #TCQ m_axis_cq_tdata_in[103:96];
                 req_be               <= #TCQ m_axis_cq_tuser_in[7:0];
                 state                <= #TCQ BMD_AXIST_RX_RST_STATE;

               end // BMD_AXIST_RX_MSG_ATS_FMT_TYPE //}

               default : begin // other TLPs //{

                 state        <= #TCQ BMD_AXIST_RX_RST_STATE;
               end //}

             endcase // Req_Type_fsm //}
           end //sop_if //}

         end // BMD_AXIST_RX_RST_STATE //}


         BMD_AXIST_RX_DATA : begin //{

           if (m_axis_cq_tvalid )
           begin //{
             wr_addr          <= #TCQ req_addr[12:2];
             case (data_start_loc[1:0]) //{
               2'b00 : begin //{
                 wr_data[31:0]    <= #TCQ m_axis_cq_tdata_q[159:128] ;
                 wr_data[63:32]    <= #TCQ payload_len ? m_axis_cq_tdata_q[191:160] : 32'h0;
                 wr_be            <= #TCQ payload_len ? m_axis_cq_tuser_q[39:32] : { 4'h0, m_axis_cq_tuser_q[35:32]};
                 wr_en            <= #TCQ 1'b1;
                 state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                 m_axis_cq_tready <= #TCQ 1'b0;
               end //}
               2'b01 : begin //{
                 wr_data[31:0]    <= #TCQ m_axis_cq_tdata_q[191:160] ;
                 wr_data[63:32]    <= #TCQ payload_len ? m_axis_cq_tdata_q[223:192] : 32'h0;
                 wr_be            <= #TCQ payload_len ? m_axis_cq_tuser_q[42:36] : { 4'h0, m_axis_cq_tuser_q[39:36]};
                 wr_en            <= #TCQ 1'b1;
                 state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                 m_axis_cq_tready <= #TCQ 1'b0;
               end //}
               2'b10 : begin //{
                 wr_data[31:0]    <= #TCQ m_axis_cq_tdata_q[223:192] ;
                 wr_data[63:32]    <= #TCQ payload_len ? m_axis_cq_tdata_q[255:224] : 32'h0;
                 wr_be            <= #TCQ payload_len ? m_axis_cq_tuser_q[47:40] : { 4'h0, m_axis_cq_tuser_q[43:40]};
                 wr_en            <= #TCQ 1'b1;
                 state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                 m_axis_cq_tready <= #TCQ 1'b0;
               end //}
               2'b11 : begin //{
                 wr_data[31:0]    <= #TCQ m_axis_cq_tdata_q[255:224];
                 wr_data[63:32]    <= #TCQ payload_len ? m_axis_cq_tdata_q[287:256] : 32'h0;
                 wr_be            <= #TCQ payload_len ? m_axis_cq_tuser_q[51:44] : { 4'h0, m_axis_cq_tuser_q[47:44]};
                 wr_en            <= #TCQ 1'b1;
                 state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
                 m_axis_cq_tready <= #TCQ 1'b0;
               end //}
               default : begin //{
                 state        <= #TCQ BMD_AXIST_RX_DATA;
               end //}
             endcase //}
           end // if (m_axis_cq_tvalid) //}
           else
             state        <= #TCQ BMD_AXIST_RX_DATA;

         end // BMD_AXIST_RX_DATA //}

         BMD_AXIST_RX_DATA2 : begin //{

           if (m_axis_cq_tvalid && m_axis_cq_tlast)
           begin //{
             if ( (payload_len == 11'h002) && (AXISTEN_IF_CMP_ALIGNMENT_MODE != 2'b00))
             begin // Address Aligned Mode //{
               wr_data[63:32]   <= #TCQ m_axis_cq_tdata_in[31:0];
               wr_be[7:4]       <= #TCQ m_axis_cq_tuser_in[11:8];
               wr_en            <= #TCQ 1'b1;
               m_axis_cq_tready <= #TCQ 1'b0;
               state            <= #TCQ BMD_AXIST_RX_WAIT_STATE;
             end //}

           end // if (m_axis_cq_tvalid) //}
           else
           state        <= #TCQ BMD_AXIST_RX_DATA2;

         end // BMD_AXIST_RX_DATA2 //}

         BMD_AXIST_RX_WAIT_STATE : begin //{

           wr_en      <= #TCQ 1'b0;
           req_compl  <= #TCQ 1'b0;
           req_compl_wd  <= #TCQ 1'b0;

           if ((trn_type == BMD_AXIST_RX_MEM_WR_FMT_TYPE) && (!wr_busy))
           begin //{

             m_axis_cq_tready <= #TCQ 1'b1;
             state        <= #TCQ BMD_AXIST_RX_RST_STATE;

           end else if ((trn_type == BMD_AXIST_RX_IO_WR_FMT_TYPE) && (!wr_busy))  //}
           begin //{

             m_axis_cq_tready <= #TCQ 1'b1;
             state        <= #TCQ BMD_AXIST_RX_RST_STATE;

           end else if ((trn_type == BMD_AXIST_RX_MEM_RD_FMT_TYPE) && (compl_done)) //}
           begin //{

             m_axis_cq_tready <= #TCQ 1'b1;
             state        <= #TCQ BMD_AXIST_RX_RST_STATE;

           end else if ((trn_type == BMD_AXIST_RX_MEM_LK_RD_FMT_TYPE) && (compl_done)) //}
           begin //{

             m_axis_cq_tready <= #TCQ 1'b1;
             state        <= #TCQ BMD_AXIST_RX_RST_STATE;

           end else if ((trn_type == BMD_AXIST_RX_IO_RD_FMT_TYPE) && (compl_done)) //}
           begin //{

             m_axis_cq_tready <= #TCQ 1'b1;
             state        <= #TCQ BMD_AXIST_RX_RST_STATE;

           end else if (((trn_type == BMD_AXIST_RX_ATOP_FAA_FMT_TYPE) || (trn_type == BMD_AXIST_RX_ATOP_UCS_FMT_TYPE) || //}
                         (trn_type == BMD_AXIST_RX_ATOP_CAS_FMT_TYPE)) && (compl_done))
           begin //{

             m_axis_cq_tready <= #TCQ 1'b1;
             state        <= #TCQ BMD_AXIST_RX_RST_STATE;
           end else //}
             state        <= #TCQ BMD_AXIST_RX_WAIT_STATE;

         end // BMD_AXIST_RX_WAIT_STATE //}
       endcase // state //}
     end // reset_n //}
   end // End of always Block //}

   assign io_bar_hit_n    = (m_axis_cq_tdata_in.bar_id == 3'b010) ? 1'b0 : 1'b1;
   assign mem64_bar_hit_n = 1'b1;
   assign erom_bar_hit_n  = (m_axis_cq_tdata_in.bar_id == 3'b110) ? 1'b0 : 1'b1;
   assign mem32_bar_hit_n = (m_axis_cq_tdata_in.bar_id == 3'b000) ? 1'b0 : 1'b1;

   always_comb begin
      case ({io_bar_hit_n, mem32_bar_hit_n, mem64_bar_hit_n, erom_bar_hit_n})
         4'b0111 : region_select = 2'b00; // Select IO region
         4'b1011 : region_select = 2'b01; // Select Mem32 region
         4'b1101 : region_select = 2'b10; // Select Mem64 region
         4'b1110 : region_select = 2'b11; // Select EROM region
         default : region_select = 2'b00; // Error selection will select IO region
      endcase
   end

   // Not used
   //assign pcie_cq_np_req = 'd1;

endmodule
