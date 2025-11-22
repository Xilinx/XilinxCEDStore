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
module BMD_AXIST_RQ_RW_1024 #(
   parameter         AXISTEN_IF_REQ_ALIGNMENT_MODE =    0
  ,parameter         AXISTEN_IF_RQ_STRADDLE        = 2'b10 //00: max 1 packet, 01: max 2, 10: max 4, 11: rsvd
  ,parameter         AXISTEN_IF_REQ_PARITY_CHECK   =    0
  ,parameter         AXI4_RQ_TUSER_WIDTH           =  137
  ,parameter         SEQ_NUM_IGNORE                =    0
  ,parameter [0:0]   AXISTEN_IF_ENABLE_CLIENT_TAG  = 0
  ,parameter         RQ_AVAIL_TAG_IDX              = 8
  ,parameter         RQ_AVAIL_TAG                  = 256
  ,parameter         TCQ                           =    1
  ,parameter         C_DATA_WIDTH                  = 1024
  ,parameter         KEEP_WIDTH                    = C_DATA_WIDTH/32
)(
   // Clock and Reset
   input                                  user_clk
  ,input                                  reset_n
  ,input                                  init_rst_i

   // AXI-S Requester Request Interface
  ,output logic                           s_axis_rq_tlast
  ,output logic [C_DATA_WIDTH-1:0]        s_axis_rq_tdata
  ,output logic [AXI4_RQ_TUSER_WIDTH-1:0] s_axis_rq_tuser
  ,output logic [KEEP_WIDTH-1:0]          s_axis_rq_tkeep
  ,input                                  s_axis_rq_tready
  ,output logic                           s_axis_rq_tvalid
  ,input        [5:0]                     curr_seq_num
  ,output logic                           seq_num_assigned_0
  ,output logic                           seq_num_assigned_1
   // Client Tag
  ,input                            client_tag_released_0,
   input                            client_tag_released_1,
   input                            client_tag_released_2,
   input                            client_tag_released_3,
   input                            client_tag_released_4,
   input                            client_tag_released_5,
   input                            client_tag_released_6,
   input                            client_tag_released_7,

   input        [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_0,
   input        [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_1,
   input        [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_2,
   input        [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_3,
   input        [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_4,
   input        [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_5,
   input        [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_6,
   input        [RQ_AVAIL_TAG_IDX-1:0] client_tag_released_num_7,

   output logic                        tags_all_back,

   input                               cfg_10b_tag_requester_enable

 
   // from control register
  ,input                                  mwr_start_i
  ,input        [10:0]                    mwr_len_i
  ,input        [31:0]                    mwr_addr_i
  ,input        [31:0]                    mwr_data_i
  ,input        [15:0]                    mwr_count_i
  ,input        [ 7:0]                    mwr_wrr_cnt_i
  ,output logic                           mwr_done_o

  ,input                                  mrd_start_i
  ,input        [10:0]                    mrd_len_i
  ,input        [31:0]                    mrd_addr_i
  ,input        [15:0]                    mrd_count_i
  ,input        [ 7:0]                    mrd_wrr_cnt_i
  ,output logic                           mrd_done_o
);
   `STRUCT_AXI_RQ_IF_1024
localparam RD_STRADDLE_NUM = AXISTEN_IF_RQ_STRADDLE[1] ? 4 : 2;

//--------------------------------------------------------------------
//  States Overview
//--------------------------------------------------------------------
/*
enum {
  IDLE
 //,EVAL        // 0x0  : evaluation: take some cycles for straddling data
 ,WR_32DW_DW0   // 0x1  : WR data > 28 DW  -> Size will be multiple of 32, Header @ DW0           - NEXT STATE OF IDLE
 ,WR_32DW_DW8   // 0x2  : WR data > 28 DW  -> Size will be multiple of 32, Header @ DW8
 ,WR_32DW_DW16  // 0x3  : WR data > 28 DW  -> Size will be multiple of 32, Header @ DW16
 ,WR_32DW_DW24  // 0x4  : WR data > 28 DW  -> Size will be multiple of 32, Header @ DW24
 ,WR_32DW_DATA  // 0x5  : WR data > 28 DW, Data only (no header)
 //,WR_20DW_DW0 // 0x-  : WR data - (20,28] DW -> not possible since size has to be power of 2
 //,WR_20DW_DW16// 0x-  : WR data - (20,28] DW -> not possible since size has to be power of 2
 ,WR_16DW_DW0   // 0x6  : WR data - (12,20] DW   -> must be 16 DW, Header @ DW0                   - NEXT STATE OF IDLE
 ,WR_16DW_DW16  // 0x7  : WR data - (12,20] DW   -> must be 16 DW, Header @ DW16 ** can start from this state when wr after rd
 ,WR_16DW_DW8   // 0x8  : WR data - (12,20] DW   -> must be 16 DW, Header @ DW8 
 ,WR_16DW_DATA  // 0x9  : WR data - (12,20] DW   -> must be 16 DW, no header, only in end of write packet 
 ,WR_8DW        // 0xa  : WR data - ( 4,12] DW   -> must be 8 DW - two TLP @ DW0, DW8             - NEXT STATE OF IDLE
 ,WR_SMALL_4    // 0xb  : WR data < 4 DW - 4 TLP @ DW0, DW8, DW16, DW24                           - NEXT STATE OF IDLE
 ,WR_SMALL_2    // 0xc  : WR data < 4 DW - 2 TLP @ DW0, DW8
 ,RD_ONLY_2     // 0xd  : RD TLP only 
 ,RD_ONLY_4     // 0xe  : RD TLP only 
 ,RAW           // 0xf  : RD after WR (WR + RD) - NEXT STATE OF IDLE
 ,WAR_1HDR      // 0x10  : WR after RD (RD + WR) 1 WR packet after RD  - **wr after rd only
 ,WAR_2HDR      // 0x11  : WR after RD (RD + WR) 2 WR packets after RD - **wr after rd only
 // no straddle states
 ,WR_HEADER     // 0x12
 ,WR_DATA       // 0x13
 ,RD            // 0x14
 ,DONE          // 0x15   // Last state before going back to IDLE to make sure last packet sent out correctly and then raise rq_done
} state, nxt_state; 
*/
  (*make_debug*)(*keep*) logic [4:0] state; 
  logic [4:0] nxt_state; 

  localparam IDLE          = 5'h00;      

  localparam WR_32DW_DW0   = 5'h1 ; //: WR data > 28 DW  -> Size will be multiple of 32, Header @ DW0           - NEXT STATE OF IDLE
  localparam WR_32DW_DW8   = 5'h2 ; //: WR data > 28 DW  -> Size will be multiple of 32, Header @ DW8
  localparam WR_32DW_DW16  = 5'h3 ; //: WR data > 28 DW  -> Size will be multiple of 32, Header @ DW16
  localparam WR_32DW_DW24  = 5'h4 ; //: WR data > 28 DW  -> Size will be multiple of 32, Header @ DW24
  localparam WR_32DW_DATA  = 5'h5 ; //: WR data > 28 DW, Data only (no header)


  localparam WR_16DW_DW0   = 5'h6 ; //: WR data - (12,20] DW   -> must be 16 DW, Header @ DW0                   - NEXT STATE OF IDLE
  localparam WR_16DW_DW16  = 5'h7 ; //: WR data - (12,20] DW   -> must be 16 DW, Header @ DW16 ** can start from this state when wr after rd
  localparam WR_16DW_DW8   = 5'h8 ; //: WR data - (12,20] DW   -> must be 16 DW, Header @ DW8 
  localparam WR_16DW_DATA  = 5'h9 ; //: WR data - (12,20] DW   -> must be 16 DW, no header, only in end of write packet 
  localparam WR_8DW        = 5'ha ; //: WR data - ( 4,12] DW   -> must be 8 DW - two TLP @ DW0, DW8             - NEXT STATE OF IDLE
  localparam WR_SMALL_4    = 5'hb ; //: WR data < 4 DW - 4 TLP @ DW0, DW8, DW16, DW24                           - NEXT STATE OF IDLE
  localparam WR_SMALL_2    = 5'hc ; //: WR data < 4 DW - 2 TLP @ DW0, DW8
  localparam RD_ONLY_2     = 5'hd ; //: RD TLP only 
  localparam RD_ONLY_4     = 5'he ; //: RD TLP only 
  localparam RAW           = 5'hf ; //: RD after WR (WR + RD) - NEXT STATE OF IDLE
  localparam WAR_1HDR      = 5'h10; // : WR after RD (RD + WR) 1 WR packet after RD  - **wr after rd only
  localparam WAR_2HDR      = 5'h11; // : WR after RD (RD + WR) 2 WR packets after RD - **wr after rd only

  localparam WR_HEADER     = 5'h12;
  localparam WR_DATA       = 5'h13;
  localparam RD            = 5'h14;
  localparam DONE          = 5'h15; //  // Last state before going back to IDLE to make sure last packet sent out correctly and then raise rq_done
//--------------------------------------------------------------------
//  Internal Signal Declare
//--------------------------------------------------------------------

   // counters for request RD/WR address
   logic [29:0]   wr_addr_31_2_0, wr_addr_31_2_1, wr_addr_31_2_2, wr_addr_31_2_3;
   logic [29:0]   rd_addr_31_2_0, rd_addr_31_2_1, rd_addr_31_2_2, rd_addr_31_2_3;
   logic [15:0]   w_tcnt, w_tcnt_w; 
   logic [15:0]   r_tcnt, r_tcnt_w; 

   // counters/flags for state machine
   logic [15:0]   curr_mwr_count;
   logic [15:0]   curr_mrd_count;
   logic [31-5:0] curr_mwr_len;
   logic [1:0]    wr_end_case;
   logic [15:0]   curr_mwr_wrr_cnt;
   logic [15:0]   curr_mrd_wrr_cnt;
   logic          mwr_en,    mrd_en;
   
   logic [15:0]   curr_mwr_count_w;
   logic [15:0]   curr_mrd_count_w;
   logic [31-5:0] curr_mwr_len_w;
   logic [1:0]    wr_end_case_w;
   logic [15:0]   curr_mwr_wrr_cnt_w;
   logic [15:0]   curr_mrd_wrr_cnt_w;
   
   logic          rq_done,   rq_done_w;
   logic          interl_en, interl_en_w;
   logic  [3:0]   mwr_len_log2;
   logic  [3:0]   mrd_len_log2;
   logic  [2:0]   mwr_len_case;

   // internal AXI RQ bus
   s_axis_rq_tdata_1024    s_axis_rq_tdata_w;
   s_axis_rq_tdata_1024    s_axis_rq_tdata_reg ;
   logic [KEEP_WIDTH-1:0]  s_axis_rq_tkeep_w;
   logic                   s_axis_rq_tlast_w;
   logic                   s_axis_rq_tvalid_w;
   s_axis_rq_tuser_1024    s_axis_rq_tuser_w;
   s_axis_rq_tuser_1024    s_axis_rq_tuser_reg;
   s_axis_rq_tuser_1024    s_axis_rq_tuser_w_parity;
   logic [63:0]   s_axis_rq_parity; // TODO
 
//--------------------------------------------------------------------
//  Wire Assignment
//--------------------------------------------------------------------
   assign mwr_len_case     = wr_len_interval(mwr_len_i); // TODO: can be optimized 
   assign mwr_en           = mwr_start_i & (mwr_count_i[15:0] != 0) & ~rq_done;
   assign mrd_en           = mrd_start_i & (mrd_count_i[15:0] != 0) & ~rq_done;

   assign mwr_done_o = mwr_start_i & rq_done;
   assign mrd_done_o = mrd_start_i & rq_done;

   // counter for address
   assign mwr_len_log2   = log_case(mwr_len_i);
   assign mrd_len_log2   = log_case(mrd_len_i);
   assign wr_addr_31_2_0 = mwr_addr_i[31:2] + (  w_tcnt[15:0]      << mwr_len_log2 );
   assign wr_addr_31_2_1 = mwr_addr_i[31:2] + ( (w_tcnt[15:0] + 1) << mwr_len_log2 );
   assign wr_addr_31_2_2 = mwr_addr_i[31:2] + ( (w_tcnt[15:0] + 2) << mwr_len_log2 );
   assign wr_addr_31_2_3 = mwr_addr_i[31:2] + ( (w_tcnt[15:0] + 3) << mwr_len_log2 );
   assign rd_addr_31_2_0 = mrd_addr_i[31:2] + (  r_tcnt[15:0]      << mrd_len_log2 );
   assign rd_addr_31_2_1 = mrd_addr_i[31:2] + ( (r_tcnt[15:0] + 1) << mrd_len_log2 );
   assign rd_addr_31_2_2 = mrd_addr_i[31:2] + ( (r_tcnt[15:0] + 2) << mrd_len_log2 );
   assign rd_addr_31_2_3 = mrd_addr_i[31:2] + ( (r_tcnt[15:0] + 3) << mrd_len_log2 );

//TODO
  assign seq_num_assigned_0 = 0; 
  assign seq_num_assigned_1 = 0;
// Client tag
  logic          client_tag_assigned_0, client_tag_assigned_0_wire;
  logic          client_tag_assigned_1, client_tag_assigned_1_wire;
  logic          client_tag_assigned_2, client_tag_assigned_2_wire;
  logic          client_tag_assigned_3, client_tag_assigned_3_wire;
  logic [9:0]    client_tag_assigned_num_0, client_tag_assigned_num_0_d1, client_tag_assigned_num_0_wire;
  logic [9:0]    client_tag_assigned_num_1, client_tag_assigned_num_1_d1, client_tag_assigned_num_1_wire;
  logic [9:0]    client_tag_assigned_num_2, client_tag_assigned_num_2_d1, client_tag_assigned_num_2_wire;
  logic [9:0]    client_tag_assigned_num_3, client_tag_assigned_num_3_d1, client_tag_assigned_num_3_wire;
  logic [9:0]    client_tag_assigned_num_10bit_0;
  logic [9:0]    client_tag_assigned_num_10bit_1;
  logic [9:0]    client_tag_assigned_num_10bit_2;
  logic [9:0]    client_tag_assigned_num_10bit_3;
  logic [1023:0]                avail_client_tag, avail_client_tag_wire;
  //logic [RQ_AVAIL_TAG-1:0]      avail_client_tag, avail_client_tag_wire;
  logic [RQ_AVAIL_TAG-1:0]      client_tag_assigned_vec_0;
  logic [RQ_AVAIL_TAG-1:0]      client_tag_assigned_vec_1;
  logic [RQ_AVAIL_TAG-1:0]      client_tag_assigned_vec_2;
  logic [RQ_AVAIL_TAG-1:0]      client_tag_assigned_vec_3;
  logic [RQ_AVAIL_TAG-1:0]      client_tag_released_vec_0;
  logic [RQ_AVAIL_TAG-1:0]      client_tag_released_vec_1;
  logic [RQ_AVAIL_TAG-1:0]      client_tag_released_vec_2;
  logic [RQ_AVAIL_TAG-1:0]      client_tag_released_vec_3;
  logic [RQ_AVAIL_TAG-1:0]      client_tag_released_vec_4;
  logic [RQ_AVAIL_TAG-1:0]      client_tag_released_vec_5;
  logic [RQ_AVAIL_TAG-1:0]      client_tag_released_vec_6;
  logic [RQ_AVAIL_TAG-1:0]      client_tag_released_vec_7;

  logic [3:0]                   next_client_tag_available;
  logic                         waiting_for_next_tag;
  logic [3:0]                   tags_all_back_i;
   
 // Make encoded tags become vectors
  genvar var_j;
  generate
    for (var_j = 0; var_j < RQ_AVAIL_TAG; var_j = var_j + 1) begin: gen_tag_vec
      assign client_tag_assigned_vec_0[var_j]   = client_tag_assigned_0 & (client_tag_assigned_num_0_d1[RQ_AVAIL_TAG_IDX-1:0] == var_j);
      assign client_tag_assigned_vec_1[var_j]   = client_tag_assigned_1 & (client_tag_assigned_num_1_d1[RQ_AVAIL_TAG_IDX-1:0] == var_j);
      assign client_tag_assigned_vec_2[var_j]   = client_tag_assigned_2 & (client_tag_assigned_num_2_d1[RQ_AVAIL_TAG_IDX-1:0] == var_j);
      assign client_tag_assigned_vec_3[var_j]   = client_tag_assigned_3 & (client_tag_assigned_num_3_d1[RQ_AVAIL_TAG_IDX-1:0] == var_j);
      assign client_tag_released_vec_0[var_j]   = client_tag_released_0 & (client_tag_released_num_0[RQ_AVAIL_TAG_IDX-1:0] == var_j);
      assign client_tag_released_vec_1[var_j]   = client_tag_released_1 & (client_tag_released_num_1[RQ_AVAIL_TAG_IDX-1:0] == var_j);
      assign client_tag_released_vec_2[var_j]   = client_tag_released_2 & (client_tag_released_num_2[RQ_AVAIL_TAG_IDX-1:0] == var_j);
      assign client_tag_released_vec_3[var_j]   = client_tag_released_3 & (client_tag_released_num_3[RQ_AVAIL_TAG_IDX-1:0] == var_j);
      assign client_tag_released_vec_4[var_j]   = client_tag_released_4 & (client_tag_released_num_4[RQ_AVAIL_TAG_IDX-1:0] == var_j);
      assign client_tag_released_vec_5[var_j]   = client_tag_released_5 & (client_tag_released_num_5[RQ_AVAIL_TAG_IDX-1:0] == var_j);
      assign client_tag_released_vec_6[var_j]   = client_tag_released_6 & (client_tag_released_num_6[RQ_AVAIL_TAG_IDX-1:0] == var_j);
      assign client_tag_released_vec_7[var_j]   = client_tag_released_7 & (client_tag_released_num_7[RQ_AVAIL_TAG_IDX-1:0] == var_j);
    end   
  endgenerate

   assign avail_client_tag_wire  = (avail_client_tag
                                    & ~({RQ_AVAIL_TAG{client_tag_assigned_0}} & client_tag_assigned_vec_0)
                                    & ~({RQ_AVAIL_TAG{client_tag_assigned_1}} & client_tag_assigned_vec_1)
                                    & ~({RQ_AVAIL_TAG{client_tag_assigned_2}} & client_tag_assigned_vec_2)
                                    & ~({RQ_AVAIL_TAG{client_tag_assigned_3}} & client_tag_assigned_vec_3)
                                    | ({RQ_AVAIL_TAG{client_tag_released_0}} & client_tag_released_vec_0)
                                    | ({RQ_AVAIL_TAG{client_tag_released_1}} & client_tag_released_vec_1)
                                    | ({RQ_AVAIL_TAG{client_tag_released_2}} & client_tag_released_vec_2)
                                    | ({RQ_AVAIL_TAG{client_tag_released_3}} & client_tag_released_vec_3)
                                    | ({RQ_AVAIL_TAG{client_tag_released_4}} & client_tag_released_vec_4)
                                    | ({RQ_AVAIL_TAG{client_tag_released_5}} & client_tag_released_vec_5)
                                    | ({RQ_AVAIL_TAG{client_tag_released_6}} & client_tag_released_vec_6)
                                    | ({RQ_AVAIL_TAG{client_tag_released_7}} & client_tag_released_vec_7));
   `BMDREG(user_clk, (reset_n & ~init_rst_i), avail_client_tag, avail_client_tag_wire, {RQ_AVAIL_TAG{1'b1}})

   assign client_tag_assigned_num_10bit_0  = cfg_10b_tag_requester_enable ? client_tag_assigned_num_0[9:0] : {2'b00,client_tag_assigned_num_0[7:0]};
   assign client_tag_assigned_num_10bit_1  = cfg_10b_tag_requester_enable ? client_tag_assigned_num_1[9:0] : {2'b00,client_tag_assigned_num_1[7:0]};
   assign client_tag_assigned_num_10bit_2  = cfg_10b_tag_requester_enable ? client_tag_assigned_num_2[9:0] : {2'b00,client_tag_assigned_num_2[7:0]};
   assign client_tag_assigned_num_10bit_3  = cfg_10b_tag_requester_enable ? client_tag_assigned_num_3[9:0] : {2'b00,client_tag_assigned_num_3[7:0]};
   
   //assign tags_all_back = (cfg_10b_tag_requester_enable ? &avail_client_tag[1023:0] : &avail_client_tag[255:0]) | ~AXISTEN_IF_ENABLE_CLIENT_TAG;
   assign tags_all_back = AXISTEN_IF_ENABLE_CLIENT_TAG ? (cfg_10b_tag_requester_enable ? (&tags_all_back_i[3:0]) : tags_all_back_i[0]) : 1'b1;

   assign tags_all_back_i[0]    = &avail_client_tag[256*0+255:256*0];
   assign tags_all_back_i[1]    = &avail_client_tag[256*1+255:256*1];
   assign tags_all_back_i[2]    = &avail_client_tag[256*2+255:256*2];
   assign tags_all_back_i[3]    = &avail_client_tag[256*3+255:256*3];

   //assign next_client_tag_available[0] = avail_client_tag[client_tag_assigned_num_10bit_0] || ( ~AXISTEN_IF_ENABLE_CLIENT_TAG);
   //assign next_client_tag_available[1] = avail_client_tag[client_tag_assigned_num_10bit_1] || ( ~AXISTEN_IF_ENABLE_CLIENT_TAG);
   //assign next_client_tag_available[2] = avail_client_tag[client_tag_assigned_num_10bit_2] || ( ~AXISTEN_IF_ENABLE_CLIENT_TAG);
   //assign next_client_tag_available[3] = avail_client_tag[client_tag_assigned_num_10bit_3] || ( ~AXISTEN_IF_ENABLE_CLIENT_TAG);
   assign next_client_tag_available[0] = AXISTEN_IF_ENABLE_CLIENT_TAG ? avail_client_tag[client_tag_assigned_num_10bit_0] : 1'b1;
   assign next_client_tag_available[1] = AXISTEN_IF_ENABLE_CLIENT_TAG ? avail_client_tag[client_tag_assigned_num_10bit_1] : 1'b1;
   assign next_client_tag_available[2] = AXISTEN_IF_ENABLE_CLIENT_TAG ? avail_client_tag[client_tag_assigned_num_10bit_2] : 1'b1;
   assign next_client_tag_available[3] = AXISTEN_IF_ENABLE_CLIENT_TAG ? avail_client_tag[client_tag_assigned_num_10bit_3] : 1'b1;
  
//--------------------------------------------------------------------
//  State Machine
//--------------------------------------------------------------------
   generate if(AXISTEN_IF_REQ_ALIGNMENT_MODE != 2'b00 ) // Address Align - NOT SUPPORTED
   begin

     always_comb begin
        nxt_state = IDLE; // not supporting ADDR align mode
        s_axis_rq_tdata_w    = 'd0; //s_axis_rq_tdata_reg;
        s_axis_rq_tkeep_w    = 'd0; //s_axis_rq_tkeep;
        s_axis_rq_tlast_w    = 'd0; //s_axis_rq_tlast;
        s_axis_rq_tvalid_w   = 'd0; //s_axis_rq_tvalid;
        s_axis_rq_tuser_w    = 'd0; //s_axis_rq_tuser_reg;
        //seq_num_assigned_0      = 1'b0;
        //seq_num_assigned_1      = 1'b0;
     end

   end
   else // DW-align mode. generate if(AXISTEN_IF_REQ_ALIGNMENT_MODE == "TRUE")
   begin

     always_comb begin
        //**** Internal Signals **** //
        nxt_state  = state;
        w_tcnt_w            = w_tcnt;
        r_tcnt_w            = r_tcnt;
        curr_mwr_count_w    = curr_mwr_count;
        curr_mrd_count_w    = curr_mrd_count;
        curr_mwr_len_w      = curr_mwr_len;
        wr_end_case_w       = wr_end_case;
        interl_en_w         = interl_en;
        curr_mwr_wrr_cnt_w  = curr_mwr_wrr_cnt;
        curr_mrd_wrr_cnt_w  = curr_mrd_wrr_cnt;
        //**** RQ Interface **** //
        s_axis_rq_tdata_w   = s_axis_rq_tdata_reg;
        s_axis_rq_tkeep_w   = s_axis_rq_tkeep;
        s_axis_rq_tlast_w   = s_axis_rq_tlast;
        s_axis_rq_tvalid_w  = s_axis_rq_tvalid;
        s_axis_rq_tuser_w   = s_axis_rq_tuser_reg;
        rq_done_w           = rq_done;
        //seq_num_assigned_0     = 1'b0;
        //seq_num_assigned_1     = 1'b0;
        client_tag_assigned_0_wire       = 1'b0;
        client_tag_assigned_1_wire       = 1'b0;
        client_tag_assigned_2_wire       = 1'b0;
        client_tag_assigned_3_wire       = 1'b0;
        client_tag_assigned_num_0_wire   = client_tag_assigned_num_10bit_0;
        client_tag_assigned_num_1_wire   = client_tag_assigned_num_10bit_1;
        client_tag_assigned_num_2_wire   = client_tag_assigned_num_10bit_2;
        client_tag_assigned_num_3_wire   = client_tag_assigned_num_10bit_3;
        waiting_for_next_tag             = 1'b0;

        case(state[4:0])
          IDLE         : begin
                           w_tcnt_w            = 'd0;
                           r_tcnt_w            = 'd0;
                           curr_mwr_count_w    = 'd0;
                           curr_mrd_count_w    = 'd0;
                           interl_en_w         = 1'b0;
                           curr_mwr_wrr_cnt_w  = 'd0;
                           curr_mrd_wrr_cnt_w  = 'd0;
                           curr_mwr_len_w      = 'd0;
                           wr_end_case_w       = 'd0;

                           s_axis_rq_tdata_w   = 'd0;
                           s_axis_rq_tkeep_w   = 'd0;
                           s_axis_rq_tlast_w   = 'd0;
                           s_axis_rq_tvalid_w  = 'd0;
                           s_axis_rq_tuser_w   = 'd0;
                           rq_done_w           = rq_done;
                           //seq_num_assigned_0     = 1'b0;
                           //seq_num_assigned_1     = 1'b0;

                           // WR Only or WR + RD -> start from write
                           if (mwr_en) begin // Write start
                              curr_mwr_len_w = mwr_len_i >> 5; // counting multiple of 32 for rest data
                              if (mrd_en) begin // WR + RD  
                                curr_mrd_count_w    = mrd_count_i;
                                // interleave counters 
                                interl_en_w = (mwr_wrr_cnt_i != 0) & (mrd_wrr_cnt_i != 0);
                                curr_mrd_wrr_cnt_w  = mrd_wrr_cnt_i;
                              end

                              // Write Size States 
                              if (AXISTEN_IF_RQ_STRADDLE != 2'b00) begin
                                case (mwr_len_case)
                                  3'd0: begin // > 28 DW 
                                          nxt_state = WR_32DW_DW0;
                                          wr_end_case_w      = 2'd0; 
                                          curr_mwr_count_w   = mwr_count_i - 1;
                                          curr_mwr_wrr_cnt_w = (mwr_wrr_cnt_i == 0) ? 0 : mwr_wrr_cnt_i - 1;
                                        end //case -> 3'd0
                                  3'd1: nxt_state = IDLE; // (20,28] shouldn't happen, remain IDLE
                                  3'd2: begin // (12,20]
                                          nxt_state = WR_16DW_DW0;
                                          curr_mwr_count_w   = mwr_count_i - 2;
                                          curr_mwr_wrr_cnt_w = (mwr_wrr_cnt_i == 0) ? 0 : mwr_wrr_cnt_i - 2;
                                        end //case -> 3'd2
                                  3'd3: begin // ( 4,12] 
                                          nxt_state = WR_8DW;
                                          curr_mwr_count_w   = mwr_count_i - 2;
                                          curr_mwr_wrr_cnt_w = (mwr_wrr_cnt_i == 0) ? 0 : mwr_wrr_cnt_i - 2;
                                          wr_end_case_w = 2'd0; // use this flag for corner case of WAR causing 1 TLP left
                                        end //case -> 3'd3
                                  default: // < 4 DW 
                                        begin
                                          if (AXISTEN_IF_RQ_STRADDLE[0]) begin //Up to 2 TLP straddle
                                            nxt_state = WR_SMALL_2;
                                            curr_mwr_count_w   = mwr_count_i - 2;
                                            curr_mwr_wrr_cnt_w = (mwr_wrr_cnt_i == 0) ? 0 : mwr_wrr_cnt_i - 2;
                                          end 
                                          else begin // 4 TLP straddle 
                                            // if read also starts & RAW -> WR + RD 
                                            if (mrd_en && mwr_wrr_cnt_i == 2 && mrd_wrr_cnt_i != 0) begin
                                              nxt_state = RAW;
                                              curr_mwr_count_w   = mwr_count_i - 2;
                                              curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                              curr_mrd_count_w   = mrd_count_i - 2;
                                              curr_mrd_wrr_cnt_w = mrd_wrr_cnt_i - 2;
                                            end // WR + RD
                                            else if (~mrd_en && mwr_count_i == 2) begin // 2 WR only
                                              nxt_state = WR_SMALL_2;
                                              curr_mwr_count_w   = mwr_count_i - 2;
                                              curr_mwr_wrr_cnt_w = (mwr_wrr_cnt_i == 0) ? 0 : mwr_wrr_cnt_i - 2;
                                            end // WR only, 2 RD only
                                            else begin // WR only
                                              nxt_state = WR_SMALL_4;
                                              curr_mwr_count_w   = mwr_count_i - 4;
                                              curr_mwr_wrr_cnt_w = (mrd_wrr_cnt_i == 0 | mwr_wrr_cnt_i == 0) ? 0 : mwr_wrr_cnt_i - 4;
                                            end 
                                          end 
                                        end //case -> default
                                endcase // case(mwr_len_i)                             

                              end else begin // !AXISTEN_IF_RQ_STRADDLE
                                nxt_state = WR_HEADER;
                                curr_mwr_count_w = mwr_count_i - 1;
                                curr_mwr_wrr_cnt_w = (mwr_wrr_cnt_i == 0) ? 0 : mwr_wrr_cnt_i - 1;
                              end

                           end
                           // RD only 
                           else if (mrd_en) begin 
                             curr_mrd_wrr_cnt_w = 0; // no interleave because no WR
                             if (AXISTEN_IF_RQ_STRADDLE != 2'b00) begin
                               if (AXISTEN_IF_RQ_STRADDLE[0] || mrd_count_i == 2) begin
                                 nxt_state = RD_ONLY_2;  
                                 curr_mrd_count_w = mrd_count_i - 2;
                               end
                               else begin // STRADDLE 4
                                 nxt_state = RD_ONLY_4;  
                                 curr_mrd_count_w = mrd_count_i - 4;
                               end
                             end
                             else begin // !AXISTEN_IF_RQ_STRADDLE
                               nxt_state = RD;
                               curr_mrd_count_w = mrd_count_i - 1;
                             end
                           end // mrd_en 
                           else begin // no requests
                              nxt_state = IDLE;
                           end
                         end // state IDLE

          WR_32DW_DW0  : begin 
                           if(s_axis_rq_tready) begin
                             // since count can only be even, curr_mwr_count cannot be 0 in this state -> next packet must be a write packet
                             if(curr_mwr_len > 1) begin // more than 32 DW data 
                               nxt_state = WR_32DW_DATA;
                               curr_mwr_len_w = curr_mwr_len - 1;
                             end
                             else begin
                               nxt_state = WR_32DW_DW8;
                               curr_mwr_count_w   = curr_mwr_count - 1;
                               curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : curr_mwr_wrr_cnt - 1;
                               wr_end_case_w      = 2'd1;
                             end
                             // Address counting counters:
                             w_tcnt_w            = w_tcnt + 1;

                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w   = 1'b1;
                             s_axis_rq_tlast_w    = 1'b0; // tlast/tkeep not used in STRADDLE 
                             s_axis_rq_tkeep_w    = 'd0;  // tlast/tkeep not used in STRADDLE 
                             
                             s_axis_rq_tdata_w[1023:128] = {28{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.h_0.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_0.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_0.addr_63_2      = {32'd0, wr_addr_31_2_0}; 
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_0.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_0[127:79]         = 'd0;

                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;  // data won't end here
                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b00000;  // data won't end here
                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b00000;  // data won't end here
                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b00000;  // data won't end here
                             s_axis_rq_tuser_w.is_eop      = 4'b0000;   // data won't end here    
                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     // 1 Header @ DW 0 
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b00;     // 1 Header @ DW 0 
                             s_axis_rq_tuser_w.is_sop1_ptr = 2'b00;     // 1 Header @ DW 0 
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b00;     // 1 Header @ DW 0 
                             s_axis_rq_tuser_w.is_sop      = 4'b0001;   // 1 Header @ DW 0  
                             s_axis_rq_tuser_w.last_be     = 16'h000F;  // WR data > 28 DW & 0 WR eop 
                             s_axis_rq_tuser_w.first_be    = 16'h000F;  // WR data > 28 DW & 1 WR sop
                           end //if(s_axis_rq_tready) begin
                         end

          WR_32DW_DW8  : begin
                           if(s_axis_rq_tready) begin
                             interl_en_w = (curr_mwr_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                             if(curr_mwr_len > 1) begin // more than 32 DW data 
                               nxt_state = WR_32DW_DATA;
                               //curr_mwr_count == 0 && curr_mrd_count == 0: corner case -> BMD ends in this TLP
                               if( ~(curr_mwr_count == 0 && curr_mrd_count == 0) ) curr_mwr_len_w = curr_mwr_len - 1; 
                             end
                             else begin 
                               if (curr_mwr_count == 0 || (interl_en && curr_mwr_wrr_cnt == 0)) begin // no next write header 
                                 if (curr_mrd_count == 0 || AXISTEN_IF_RQ_STRADDLE[0]) begin // no read packet left or STRADDLE 2
                                   nxt_state = WR_32DW_DATA;
                                   curr_mwr_len_w = curr_mwr_len - 1;
                                 end
                                 else begin // read packet 
                                   nxt_state = RAW;
                                   curr_mrd_count_w   = curr_mrd_count - 2;
                                   curr_mrd_wrr_cnt_w = (~interl_en) ? 0 : mrd_wrr_cnt_i - 2; // interleave RD finish here, start over next interleave RD
                                 end
                               end
                               else begin // next write header will be at DW16
                                 nxt_state = WR_32DW_DW16;
                                 curr_mwr_count_w   = curr_mwr_count - 1;
                                 curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : curr_mwr_wrr_cnt - 1;
                                 wr_end_case_w = 2'd2;
                               end
                             end

                             // Address counting counters:
                             w_tcnt_w            = w_tcnt + 1;

                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w   = 1'b1;
                             s_axis_rq_tlast_w    = 1'b0; // tlast/tkeep not used in STRADDLE 
                             s_axis_rq_tkeep_w    = 'd0;  // tlast/tkeep not used in STRADDLE 
                             
                             s_axis_rq_tdata_w[1023:384] = {20{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w[ 255:  0] = { 8{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.h_1.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_1.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_1.addr_63_2      = {32'd0, wr_addr_31_2_0};
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_1.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_1[127:79]         = 'd0;

                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;  // 1 data ends @ DW3 - 12 ~ 15 byte 
                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b00000;  // 1 data ends @ DW3 - 12 ~ 15 byte 
                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b00000;  // 1 data ends @ DW3 - 12 ~ 15 byte 
                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b00011;  // 1 data ends @ DW3 - 12 ~ 15 byte 
                             s_axis_rq_tuser_w.is_eop      = 4'b0001;   // 1 data ends @ DW3 - 12 ~ 15 byte     
                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     // 1 Header @ DW 8 
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b00;     // 1 Header @ DW 8 
                             s_axis_rq_tuser_w.is_sop1_ptr = 2'b00;     // 1 Header @ DW 8 
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b01;     // 1 Header @ DW 8 
                             s_axis_rq_tuser_w.is_sop      = 4'b0001;   // 1 Header @ DW 8  
                             s_axis_rq_tuser_w.last_be     = 16'h000F;  // WR data > 28 DW & 1 WR eop  
                             s_axis_rq_tuser_w.first_be    = 16'h000F;  // WR data > 28 DW & 1 WR sop
                           end //if(s_axis_rq_tready) begin
                         end

          WR_32DW_DW16 : begin
                           if(s_axis_rq_tready) begin
                             // since count can only be even, curr_mwr_count cannot be 0 in this state
                             if(curr_mwr_len > 1) begin // more than 32 DW data 
                               nxt_state = WR_32DW_DATA;
                               curr_mwr_len_w = curr_mwr_len - 1;
                             end
                             else begin
                               nxt_state = WR_32DW_DW24;
                               curr_mwr_count_w   = curr_mwr_count - 1;
                               curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : curr_mwr_wrr_cnt - 1;
                               wr_end_case_w      = 2'd3;
                             end

                             // Address counting counters:
                             w_tcnt_w            = w_tcnt + 1;

                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w   = 1'b1;
                             s_axis_rq_tlast_w    = 1'b0; // tlast/tkeep not used in STRADDLE 
                             s_axis_rq_tkeep_w    = 'd0;  // tlast/tkeep not used in STRADDLE 
                             
                             s_axis_rq_tdata_w[1023:640] = {12{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w[ 511:  0] = {16{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.h_2.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_2.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_2.addr_63_2      = {32'd0, wr_addr_31_2_0};
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_2.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_2[127:79]         = 'd0;

                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;  // 1 data ends @ DW11 - 44 ~ 47 byte 
                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b00000;  // 1 data ends @ DW11 - 44 ~ 47 byte 
                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b00000;  // 1 data ends @ DW11 - 44 ~ 47 byte 
                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b01011;  // 1 data ends @ DW11 - 44 ~ 47 byte 
                             s_axis_rq_tuser_w.is_eop      = 4'b0001;   // 1 data ends @ DW11 - 44 ~ 47 byte     
                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     // 1 Header @ DW 16 
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b00;     // 1 Header @ DW 16 
                             s_axis_rq_tuser_w.is_sop1_ptr = 2'b00;     // 1 Header @ DW 16 
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b10;     // 1 Header @ DW 16 
                             s_axis_rq_tuser_w.is_sop      = 4'b0001;   // 1 Header @ DW 16  
                             s_axis_rq_tuser_w.last_be     = 16'h000F;  // WR data > 28 DW & 1 WR eop  
                             s_axis_rq_tuser_w.first_be    = 16'h000F;  // WR data > 28 DW & 1 WR sop
                           end //if(s_axis_rq_tready) begin
                         end

          WR_32DW_DW24 : begin
                           if(s_axis_rq_tready) begin
                             interl_en_w = (curr_mwr_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                             nxt_state = WR_32DW_DATA; // Will always need a full beat to store rest 28 DW
                             //curr_mwr_len_w = curr_mwr_len - 1;

                             // Address counting counters:
                             w_tcnt_w            = w_tcnt + 1;

                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w   = 1'b1;
                             s_axis_rq_tlast_w    = 1'b0; // tlast/tkeep not used in STRADDLE 
                             s_axis_rq_tkeep_w    = 'd0;  // tlast/tkeep not used in STRADDLE 
                             
                             s_axis_rq_tdata_w[1023:896] = { 4{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w[ 767:  0] = {24{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.h_3.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_3.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_3.addr_63_2      = {32'd0, wr_addr_31_2_0};
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_3.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_3[127:79]         = 'd0;

                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;  // 1 data ends @ DW19 - 76 ~ 79 byte 
                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b00000;  // 1 data ends @ DW19 - 76 ~ 79 byte 
                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b00000;  // 1 data ends @ DW19 - 76 ~ 79 byte 
                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b10011;  // 1 data ends @ DW19 - 76 ~ 79 byte 
                             s_axis_rq_tuser_w.is_eop      = 4'b0001;   // 1 data ends @ DW19 - 76 ~ 79 byte     
                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     // 1 Header @ DW 24 
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b00;     // 1 Header @ DW 24 
                             s_axis_rq_tuser_w.is_sop1_ptr = 2'b00;     // 1 Header @ DW 24 
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b11;     // 1 Header @ DW 24 
                             s_axis_rq_tuser_w.is_sop      = 4'b0001;   // 1 Header @ DW 24  
                             s_axis_rq_tuser_w.last_be     = 16'h000F;  // WR data > 28 DW & 1 WR eop  
                             s_axis_rq_tuser_w.first_be    = 16'h000F;  // WR data > 28 DW & 1 WR sop
                           end //if(s_axis_rq_tready) begin
                         end
          WR_32DW_DATA : begin // no header in current beat
                           if(s_axis_rq_tready) begin
                             interl_en_w = (curr_mwr_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                             if (curr_mwr_len > 1) begin // still more than 32 DW data
                               nxt_state = WR_32DW_DATA;
                               curr_mwr_len_w = curr_mwr_len - 1;
                             end
                             else if (curr_mwr_len == 0) begin // STRADDLE 2 & WR ends before DW16 & WR ends in this packet
                               curr_mwr_len_w = (curr_mwr_count == 0) ? 0 : mwr_len_i >> 5;
                               if(curr_mrd_count != 0) begin
                                 nxt_state = RD_ONLY_2;
                                 curr_mrd_count_w = curr_mrd_count - 2;
                                 curr_mrd_wrr_cnt_w = (~interl_en) ? 0 : mrd_wrr_cnt_i - 2; // no interleave because no WR
                               end
                               else begin 
                                 nxt_state = DONE;
                                 //rq_done_w = 1'b1;
                               end
                             end
                             else begin // next packet starts
                               if (curr_mwr_count == 0 || (interl_en && curr_mwr_wrr_cnt == 0)) begin // last write packet

                                 if(curr_mrd_count != 0) begin
                                   case (wr_end_case[1]) // write ends here can only be either wr_end_case == 1 or 3
                                   1'b0: begin
                                           if(AXISTEN_IF_RQ_STRADDLE[0]) begin //STRADDLE 2
                                             // need to indicate there is only 1 packets: not support RAW in STRADDLE 2
                                             nxt_state = WR_32DW_DATA;
                                             curr_mwr_len_w = curr_mwr_len - 1;
                                           end
                                           else begin
                                             nxt_state = RAW;
                                             curr_mrd_count_w = curr_mrd_count - 2;
                                             curr_mrd_wrr_cnt_w = (~interl_en) ? 0 : mrd_wrr_cnt_i - 2;// interleave RD finish here, start over next interleave RD
                                           end
                                         end
                                   1'b1: begin
                                           //ONLY happen in interleave & STRADDLE 4
                                           if(curr_mwr_count != 0 && (mrd_wrr_cnt_i == 2 || curr_mrd_count == 2) && AXISTEN_IF_RQ_STRADDLE[1]) begin 
                                             nxt_state = WAR_1HDR; 
                                             curr_mwr_count_w   = curr_mwr_count - 1;
                                             curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 1; // interleave write finish here, start over next interleave write
                                             curr_mrd_count_w   = curr_mrd_count - 2;
                                             curr_mrd_wrr_cnt_w = 0; //(~interl_en) ? 0 : curr_mrd_wrr_cnt - 2;
                                             curr_mwr_len_w = mwr_len_i >> 5;
                                             wr_end_case_w = 2'd2;
                                           end
                                           else begin
                                             if(AXISTEN_IF_RQ_STRADDLE[0] || curr_mrd_count == 2) begin
                                               nxt_state = RD_ONLY_2;
                                               curr_mrd_count_w = (curr_mrd_count == 2) ? 0: curr_mrd_count - 2;
                                               curr_mrd_wrr_cnt_w = (curr_mrd_count == 2 || ~interl_en) ? 0 : mrd_wrr_cnt_i - 2;
                                             end
                                             else begin
                                               nxt_state = RD_ONLY_4;
                                               curr_mrd_count_w = curr_mrd_count - 4;
                                               curr_mrd_wrr_cnt_w = (mrd_wrr_cnt_i == 2 || ~interl_en) ? 0 : mrd_wrr_cnt_i - 4;
                                             end
                                           end
                                         end
                                   endcase
                                 end //if(curr_mrd_count != 0)

                                 else begin //if(curr_mrd_count != 0)
                                   // interl_en will be 0 when curr_mrd_count = 0
                                   nxt_state = DONE;
                                   //rq_done_w = 1'b1;
                                 end
                               end // if(curr_mwr_count == 0)
                               else begin // curr_mwr_count != 0 -> not last write packet
                                   curr_mwr_count_w   = curr_mwr_count - 1;
                                   curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : curr_mwr_wrr_cnt - 1;
                                   curr_mwr_len_w     = mwr_len_i >> 5;
                                   case(wr_end_case)
                                     2'd0: begin 
                                             nxt_state = WR_32DW_DW8;
                                             wr_end_case_w = 2'd1;
                                           end
                                     2'd1: begin 
                                             nxt_state = WR_32DW_DW16;
                                             wr_end_case_w = 2'd2;
                                           end
                                     2'd2: begin 
                                             nxt_state = WR_32DW_DW24;
                                             wr_end_case_w = 2'd3;
                                           end
                                     2'd3: begin 
                                             nxt_state = WR_32DW_DW0;
                                             wr_end_case_w = 2'd0;
                                           end
                                   endcase
                               end // curr_mwr_count != 0 -> not last packet
                      
                             end

                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w   = 1'b1;
                             s_axis_rq_tlast_w    = 1'b0; // tlast/tkeep not used in STRADDLE 
                             s_axis_rq_tkeep_w    = 'd0;  // tlast/tkeep not used in STRADDLE 
                             
                             s_axis_rq_tdata_w[1023:0] = {32{mwr_data_i}}; // copy all data and use sop/eop to take the right part 

                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     // 0 Header
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b00;     // 0 Header
                             s_axis_rq_tuser_w.is_sop1_ptr = 2'b00;     // 0 Header
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b00;     // 0 Header
                             s_axis_rq_tuser_w.is_sop      = 4'b0000;   // 0 Header
                             s_axis_rq_tuser_w.last_be     = 16'h0000;  // WR data > 28 DW & 0 WR eop  
                             s_axis_rq_tuser_w.first_be    = 16'h0000;  // WR data > 28 DW & 0 WR sop

                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;  // at most 1 data ends here
                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b00000;  // at most 1 data ends here
                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b00000;  // at most 1 data ends here

                             //eop logic
                             if (curr_mwr_len > 1) begin // still more than 32 DW data
                               s_axis_rq_tuser_w.is_eop0_ptr = 5'b00000;  // 0 data ends
                               s_axis_rq_tuser_w.is_eop      = 4'b0000;   // 0 data ends
                             end
                             else if (curr_mwr_len == 0) begin
                               s_axis_rq_tuser_w.is_eop0_ptr = 5'b01011;  // 1 data ends @ DW11
                               s_axis_rq_tuser_w.is_eop      = 4'b0001;   // 1 data ends @ DW11
                             end
                             else begin // write ends here only when wr_end_case == 2'd3 and corner case wr_end_case == 2'd1 (very last packet)
                               s_axis_rq_tuser_w.is_eop0_ptr = (wr_end_case == 2'd3) ? 5'b11011 : 
                                                               (wr_end_case == 2'd1 && curr_mwr_count == 0 && curr_mrd_count == 0) ? 5'b01011 : 5'd0; 
                               s_axis_rq_tuser_w.is_eop      = (wr_end_case == 2'd3) ? 4'b0001  :
                                                               (wr_end_case == 2'd1 && curr_mwr_count == 0 && curr_mrd_count == 0) ? 4'b0001  : 4'd0; 
                             end
                           end //if(s_axis_rq_tready) begin
                         end // state WR_32DW_DATA

          WR_16DW_DW0  : begin // 16 DW data
                           if(s_axis_rq_tready) begin
                             interl_en_w = (curr_mwr_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                             if(curr_mwr_count == 0 || (interl_en && curr_mwr_wrr_cnt == 0)) begin //last WR packet
                               if(curr_mrd_count == 0 || AXISTEN_IF_RQ_STRADDLE[0]) begin //no RD packet or STRADDLE 2
                                 nxt_state = WR_16DW_DATA;
                               end
                               else begin
                                 nxt_state = RAW;
                                 curr_mrd_count_w = curr_mrd_count - 2;
                                 curr_mrd_wrr_cnt_w = (~interl_en) ? 0 : mrd_wrr_cnt_i - 2;
                               end
                             end
                             else begin
                               nxt_state = WR_16DW_DW16;
                               curr_mwr_count_w = curr_mwr_count - 1;
                               curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : curr_mwr_wrr_cnt - 1;
                             end

                             // Address counting counters:
                             w_tcnt_w            = w_tcnt + 2;

                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w   = 1'b1;
                             s_axis_rq_tlast_w    = 1'b0; // tlast/tkeep not used in STRADDLE 
                             s_axis_rq_tkeep_w    = 'd0;  // tlast/tkeep not used in STRADDLE 
                             
                             s_axis_rq_tdata_w.d_3 = {4{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.h_3.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_3.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_3.addr_63_2      = {32'd0, wr_addr_31_2_1};
                             s_axis_rq_tdata_w[767:128] = {20{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.h_0.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_0.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_0.addr_63_2      = {32'd0, wr_addr_31_2_0};
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_3.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_3[127:79]         = 'd0;
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_0.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_0[127:79]         = 'd0;

                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;  // 1 data ends @ DW19 - 76 ~ 79 byte 
                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b00000;  // 1 data ends @ DW19 - 76 ~ 79 byte 
                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b00000;  // 1 data ends @ DW19 - 76 ~ 79 byte 
                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b10011;  // 1 data ends @ DW19 - 76 ~ 79 byte 
                             s_axis_rq_tuser_w.is_eop      = 4'b0001;   // 1 data ends @ DW19 - 76 ~ 79 byte     
                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     // 2 Header @ DW 0, 24 
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b00;     // 2 Header @ DW 0, 24 
                             s_axis_rq_tuser_w.is_sop1_ptr = 2'b11;     // 2 Header @ DW 0, 24 
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b00;     // 2 Header @ DW 0, 24 
                             s_axis_rq_tuser_w.is_sop      = 4'b0011;   // 2 Header @ DW 0, 24  
                             s_axis_rq_tuser_w.last_be     = 16'h00FF;  // WR data > 28 DW & 1 WR eop  
                             s_axis_rq_tuser_w.first_be    = 16'h00FF;  // WR data > 28 DW & 2 WR sop
                           end //if(s_axis_rq_tready) begin
                         end // state WR_16DW_DW0

          WR_16DW_DW16 : begin
                           if(s_axis_rq_tready) begin
                             // Since rd/wr count cannot be odd numbers, counter cannot be 0 in this state
                             nxt_state = WR_16DW_DW8;
                             curr_mwr_count_w = curr_mwr_count - 1;
                             curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : curr_mwr_wrr_cnt - 1;

                             // Address counting counters:
                             w_tcnt_w            = w_tcnt + 1;

                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w   = 1'b1;
                             s_axis_rq_tlast_w    = 1'b0; // tlast/tkeep not used in STRADDLE 
                             s_axis_rq_tkeep_w    = 'd0;  // tlast/tkeep not used in STRADDLE 
                             
                             s_axis_rq_tdata_w[1023:640] = {12{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w[ 511:  0] = {16{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.h_2.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_2.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_2.addr_63_2      = {32'd0, wr_addr_31_2_0};
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_2.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_2[127:79]         = 'd0;

                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;  // 1 data ends @ DW11
                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b00000;  // 1 data ends @ DW11
                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b00000;  // 1 data ends @ DW11
                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b01011;  // 1 data ends @ DW11
                             s_axis_rq_tuser_w.is_eop      = 4'b0001;   // 1 data ends @ DW11
                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     // 1 Header @ DW 16
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b00;     // 1 Header @ DW 16
                             s_axis_rq_tuser_w.is_sop1_ptr = 2'b00;     // 1 Header @ DW 16
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b10;     // 1 Header @ DW 16
                             s_axis_rq_tuser_w.is_sop      = 4'b0001;   // 1 Header @ DW 16
                             s_axis_rq_tuser_w.last_be     = 16'h000F;  // WR data > 28 DW & 1 WR eop  
                             s_axis_rq_tuser_w.first_be    = 16'h000F;  // WR data > 28 DW & 1 WR sop
                           end //if(s_axis_rq_tready) begin

                         end // state WR_16DW_DW16

          WR_16DW_DW8  : begin
                           if(s_axis_rq_tready) begin
                             interl_en_w = (curr_mwr_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                             if(curr_mwr_count == 0 || (interl_en && curr_mwr_wrr_cnt == 0)) begin //last WR packet
                               if(curr_mrd_count == 0) begin
                                 nxt_state = DONE; // data will end in this beat
                                 //rq_done_w = 1'b1;
                               end
                               else if ((AXISTEN_IF_RQ_STRADDLE[1]) && curr_mwr_count != 0 && (mrd_wrr_cnt_i == 2 || curr_mrd_count == 2)) begin
                                 nxt_state = WAR_1HDR;
                                 curr_mwr_count_w   = curr_mwr_count - 1;
                                 curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : mwr_wrr_cnt_i - 1; // interleave write finish here, start over next interleave write
                                 curr_mrd_count_w   = curr_mrd_count - 2;
                                 curr_mrd_wrr_cnt_w = 0; //(~interl_en) ? 0 : curr_mrd_wrr_cnt - 2;
                                 curr_mwr_len_w = mwr_len_i >> 5;
                               end
                               else begin
                                 if(AXISTEN_IF_RQ_STRADDLE[0] || curr_mrd_count == 2) begin
                                   nxt_state = RD_ONLY_2;
                                   curr_mrd_count_w = curr_mrd_count - 2;
                                   curr_mrd_wrr_cnt_w = (~interl_en) ? 0 : mrd_wrr_cnt_i - 2;
                                 end
                                 else begin
                                   nxt_state = RD_ONLY_4;
                                   curr_mrd_count_w = curr_mrd_count - 4;
                                   curr_mrd_wrr_cnt_w = (~interl_en) ? 0 : mrd_wrr_cnt_i - 4;
                                 end
                               end
                             end
                             else begin
                               nxt_state = WR_16DW_DW0;
                               curr_mwr_count_w = curr_mwr_count - 2;
                               curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : curr_mwr_wrr_cnt - 2;
                             end

                             // Address counting counters:
                             w_tcnt_w            = w_tcnt + 1;

                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w   = 1'b1;
                             s_axis_rq_tlast_w    = 1'b0; // tlast/tkeep not used in STRADDLE 
                             s_axis_rq_tkeep_w    = 'd0;  // tlast/tkeep not used in STRADDLE 
                             
                             s_axis_rq_tdata_w[1023:384] = {20{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w[ 255:  0] = { 8{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.h_1.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_1.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_1.addr_63_2      = {32'd0, wr_addr_31_2_0};
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_1.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_1[127:79]         = 'd0;

                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;  // 2 data ends @ DW3, 27
                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b00000;  // 2 data ends @ DW3, 27
                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b11011;  // 2 data ends @ DW3, 27
                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b00011;  // 2 data ends @ DW3, 27
                             s_axis_rq_tuser_w.is_eop      = 4'b0011;   // 2 data ends @ DW3, 27
                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     // 1 Header @ DW 8
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b00;     // 1 Header @ DW 8
                             s_axis_rq_tuser_w.is_sop1_ptr = 2'b00;     // 1 Header @ DW 8
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b01;     // 1 Header @ DW 8
                             s_axis_rq_tuser_w.is_sop      = 4'b0001;   // 1 Header @ DW 8
                             s_axis_rq_tuser_w.last_be     = 16'h000F;  // WR data > 28 DW & 2 WR eop  
                             s_axis_rq_tuser_w.first_be    = 16'h000F;  // WR data > 28 DW & 1 WR sop
                           end //if(s_axis_rq_tready) begin
                         end // state WR_16DW_DW8

          WR_16DW_DATA : begin // last packet data 
                           if(s_axis_rq_tready) begin
                             interl_en_w = (curr_mwr_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                             if(curr_mrd_count != 0) begin // only in STRADDLE 2 there is read packet left
                               nxt_state = RD_ONLY_2;
                               curr_mrd_count_w = curr_mrd_count - 2;
                               curr_mrd_wrr_cnt_w = (~interl_en) ? 0: mrd_wrr_cnt_i - 2;
                             end
                             else begin
                               nxt_state = DONE;
                               //rq_done_w = 1'b1;
                             end
                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w   = 1'b1;
                             s_axis_rq_tlast_w    = 1'b0; // tlast/tkeep not used in STRADDLE 
                             s_axis_rq_tkeep_w    = 'd0;  // tlast/tkeep not used in STRADDLE 
                             
                             s_axis_rq_tdata_w[1023:0] = {32{mwr_data_i}}; // copy all data and use sop/eop to take the right part 

                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;  // 1 data ends @ DW11
                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b00000;  // 1 data ends @ DW11
                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b00000;  // 1 data ends @ DW11
                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b01011;  // 1 data ends @ DW11
                             s_axis_rq_tuser_w.is_eop      = 4'b0001;   // 1 data ends @ DW11
                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     // no header
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b00;     // no header
                             s_axis_rq_tuser_w.is_sop1_ptr = 2'b00;     // no header
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b00;     // no header
                             s_axis_rq_tuser_w.is_sop      = 4'b0000;   // no header
                             s_axis_rq_tuser_w.last_be     = 16'h0000;  // no sop
                             s_axis_rq_tuser_w.first_be    = 16'h0000;  // no sop
                           end //if(s_axis_rq_tready) begin
                         end // state WR_16DW_DATA

          WR_8DW       : begin // 2TLPs
                           if(s_axis_rq_tready) begin
                             interl_en_w = (curr_mwr_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                             if(curr_mwr_count == 0 || (interl_en && curr_mwr_wrr_cnt == 0)) begin //last packet
                               if(curr_mrd_count == 0) begin
                                 wr_end_case_w = 2'd0;
                                 nxt_state = DONE;
                                 //rq_done_w = 1'b1;
                               end
                               else begin
                                 if ((AXISTEN_IF_RQ_STRADDLE[1]) && curr_mwr_count != 0 && (mrd_wrr_cnt_i == 2 || curr_mrd_count == 2)) begin
                                   nxt_state = WAR_1HDR;
                                   curr_mwr_count_w   = curr_mwr_count - 1;
                                   curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : mwr_wrr_cnt_i - 1; // interleave write finish here, start over next interleave write
                                   curr_mrd_count_w   = curr_mrd_count - 2;
                                   curr_mrd_wrr_cnt_w = 0; //(~interl_en) ? 0 : curr_mrd_wrr_cnt - 2;
                                   curr_mwr_len_w = mwr_len_i >> 5;
                                 end
                                 else begin
                                   if(AXISTEN_IF_RQ_STRADDLE[0] || curr_mrd_count == 2) begin
                                     nxt_state = RD_ONLY_2;
                                     curr_mrd_count_w = curr_mrd_count - 2;
                                     curr_mrd_wrr_cnt_w = (~interl_en) ? 0 : mrd_wrr_cnt_i - 2;
                                   end
                                   else begin
                                     nxt_state = RD_ONLY_4;
                                     curr_mrd_count_w = curr_mrd_count - 4;
                                     curr_mrd_wrr_cnt_w = (~interl_en) ? 0 : mrd_wrr_cnt_i - 4;
                                   end
                                 end
                               end
                             end
                             else if(curr_mwr_count == 1 || (interl_en && curr_mwr_wrr_cnt == 1)) begin // Only happens when STRADDLE 4
                               if(curr_mrd_count == 0) begin
                                 //flag 1 WR left only
                                 nxt_state = WR_8DW;
                                 wr_end_case_w = 2'd3;
                                 curr_mwr_count_w = 0;
                                 curr_mwr_wrr_cnt_w = 0; // won't be interleaving 
                               end
                               else begin
                                 nxt_state = RAW;
                                 curr_mwr_count_w   = curr_mwr_count - 1;
                                 curr_mwr_wrr_cnt_w = 0; // won't be interleaving 
                                 curr_mrd_count_w   = curr_mrd_count - 2;
                                 curr_mrd_wrr_cnt_w = 0; // won't be interleaving 
                               end
                             end
                             else begin // next packet is still WR
                               nxt_state = WR_8DW;
                               wr_end_case_w = 2'd0;
                               curr_mwr_count_w   = curr_mwr_count - 2;
                               curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : curr_mwr_wrr_cnt - 2;
                             end

                             // Address counting counters:
                             w_tcnt_w            = (wr_end_case == 2'd3) ? w_tcnt + 1 : w_tcnt + 2;

                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w   = 1'b1;
                             s_axis_rq_tlast_w    = 1'b0; // tlast/tkeep not used in STRADDLE 
                             s_axis_rq_tkeep_w    = 'd0;  // tlast/tkeep not used in STRADDLE 
                             
                             s_axis_rq_tdata_w[1023:640] = {12{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w[ 511:128] = {12{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;  // 1 data ends @ DW11
                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b00000;  // 1 data ends @ DW11
                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     // no header
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b00;     // no header
                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b01011;  // 1st data ends @ DW11
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b00;     // 1st header starts @ DW0
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_2.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_2[127:79]         = 'd0;
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_0.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_0[127:79]         = 'd0;
                             
                             if(wr_end_case != 2'd3) begin
                               s_axis_rq_tdata_w.h_2.req_type       = 4'b0001; // MemWr
                               s_axis_rq_tdata_w.h_2.dword_count    = mwr_len_i;
                               s_axis_rq_tdata_w.h_2.addr_63_2      = {32'd0, wr_addr_31_2_1};
                               s_axis_rq_tdata_w.h_0.req_type       = 4'b0001; // MemWr
                               s_axis_rq_tdata_w.h_0.dword_count    = mwr_len_i;
                               s_axis_rq_tdata_w.h_0.addr_63_2      = {32'd0, wr_addr_31_2_0};
                               s_axis_rq_tuser_w.is_eop1_ptr = 5'b11011;  // 2nd data ends @ DW27
                               s_axis_rq_tuser_w.is_eop      = 4'b0011;   // 2 data ends
                               s_axis_rq_tuser_w.is_sop1_ptr = 2'b10;     // 2nd header starts @ DW16
                               s_axis_rq_tuser_w.is_sop      = 4'b0011;   // 2 header
                               s_axis_rq_tuser_w.last_be     = 16'h00FF;  // WR data > 28 DW & 2 WR eop  
                               s_axis_rq_tuser_w.first_be    = 16'h00FF;  // WR data > 28 DW & 2 WR sop
                             end //if(wr_end_case != 2'd3) begin
                             else begin
                               s_axis_rq_tdata_w.h_2                = {4{mwr_data_i}}; // MemWr
                               s_axis_rq_tdata_w.h_0.req_type       = 4'b0001; // MemWr
                               s_axis_rq_tdata_w.h_0.dword_count    = mwr_len_i;
                               s_axis_rq_tdata_w.h_0.addr_63_2      = {32'd0, wr_addr_31_2_0};
                               s_axis_rq_tuser_w.is_eop1_ptr = 5'b0;     // no 2nd data 
                               s_axis_rq_tuser_w.is_eop      = 4'b0001;  // 1 data ends
                               s_axis_rq_tuser_w.is_sop1_ptr = 2'b0;     // no 2nd header
                               s_axis_rq_tuser_w.is_sop      = 4'b0001;  // 1 header
                               s_axis_rq_tuser_w.last_be     = 16'h000F; // WR data > 28 DW & 1 WR eop  
                               s_axis_rq_tuser_w.first_be    = 16'h000F; // WR data > 28 DW & 1 WR sop
                             end 
                           end //if(s_axis_rq_tready) begin
                         end // state WR_8DW

          WR_SMALL_4   : begin // 4 TLPs, ** Only go into this state when STRADDLE 4
                           if(s_axis_rq_tready) begin
                             interl_en_w = (curr_mwr_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                             if(curr_mwr_count == 2 || (interl_en && curr_mwr_wrr_cnt == 2)) begin //last packet
                               if(curr_mrd_count == 0) begin
                                 nxt_state = WR_SMALL_2;
                                 curr_mwr_count_w = curr_mwr_count - 2;
                                 curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : curr_mwr_wrr_cnt - 2;
                               end
                               else begin
                                 nxt_state = RAW;
                                 curr_mwr_count_w = curr_mwr_count - 2;
                                 curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : curr_mwr_wrr_cnt - 2;
                                 curr_mrd_count_w = curr_mrd_count - 2;
                                 curr_mrd_wrr_cnt_w = (~interl_en) ? 0 : mrd_wrr_cnt_i - 2;
                               end
                             end
                             else if(curr_mwr_count == 0 || (interl_en) && curr_mwr_wrr_cnt == 0) begin //last packet
                               if(curr_mrd_count == 0) begin
                                 nxt_state = DONE;
                                 //rq_done_w = 1'b1;
                               end
                               else begin
                                 if (curr_mwr_count != 0 && mrd_wrr_cnt_i == 2) begin
                                   nxt_state = WAR_2HDR;
                                   curr_mwr_count_w   = curr_mwr_count - 2;
                                   curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : mwr_wrr_cnt_i - 2; // interleave write finish here, start over next interleave write
                                   curr_mrd_count_w   = curr_mrd_count - 2;
                                   curr_mrd_wrr_cnt_w = 0;
                                 end
                                 else begin
                                   if(curr_mrd_count == 2) begin
                                     nxt_state = RD_ONLY_2;
                                     curr_mrd_count_w   = 0;
                                     curr_mrd_wrr_cnt_w = 0;
                                   end
                                   else begin
                                     nxt_state = RD_ONLY_4;
                                     curr_mrd_count_w = curr_mrd_count - 4;
                                     curr_mrd_wrr_cnt_w = (~interl_en) ? 0 : mrd_wrr_cnt_i - 4;
                                   end
                                 end
                               end
                             end
                             else begin
                               nxt_state = WR_SMALL_4;
                               curr_mwr_count_w = curr_mwr_count - 4;
                               curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : curr_mwr_wrr_cnt - 4;
                             end

                             // Address counting counters:
                             w_tcnt_w            = w_tcnt + 4;

                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w   = 1'b1;
                             s_axis_rq_tlast_w    = 1'b0; // tlast/tkeep not used in STRADDLE 
                             s_axis_rq_tkeep_w    = 'd0;  // tlast/tkeep not used in STRADDLE 
                             
                             s_axis_rq_tdata_w.d_3 = {4{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.d_2 = {4{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.d_1 = {4{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.d_0 = {4{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.h_3.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_3.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_3.addr_63_2      = {32'd0, wr_addr_31_2_3};
                             s_axis_rq_tdata_w.h_2.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_2.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_2.addr_63_2      = {32'd0, wr_addr_31_2_2};
                             s_axis_rq_tdata_w.h_1.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_1.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_1.addr_63_2      = {32'd0, wr_addr_31_2_1};
                             s_axis_rq_tdata_w.h_0.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_0.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_0.addr_63_2      = {32'd0, wr_addr_31_2_0};
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_3.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_3[127:79]         = 'd0;
                             s_axis_rq_tdata_w.h_2.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_2[127:79]         = 'd0;
                             s_axis_rq_tdata_w.h_1.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_1[127:79]         = 'd0;
                             s_axis_rq_tdata_w.h_0.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_0[127:79]         = 'd0;
                             s_axis_rq_tuser_w.is_eop      = 4'b1111; 
                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b11;     
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b10;     
                             s_axis_rq_tuser_w.is_sop1_ptr = 2'b01;     
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b00;     
                             s_axis_rq_tuser_w.is_sop      = 4'b1111;   
                             s_axis_rq_tuser_w.last_be     = (mwr_len_i[0]) ? 16'h0 : 16'hFFFF;  
                             s_axis_rq_tuser_w.first_be    = 16'hFFFF;  
                             case(1'b1)
                             mwr_len_i[0]: begin //1DW
                                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b11100; // DW28 
                                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b10100; // DW20 
                                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b01100; // DW12 
                                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b00100; // DW4 
                                           end
                             mwr_len_i[1]: begin //2DW
                                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b11101; // DW29 
                                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b10101; // DW21 
                                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b01101; // DW13 
                                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b00101; // DW5 
                                           end
                             mwr_len_i[2]: begin //4DW
                                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b11111; // DW31 
                                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b10111; // DW23 
                                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b01111; // DW15 
                                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b00111; // DW7 
                                           end
                             endcase
                           end //if(s_axis_rq_tready) begin
                         end // state WR_SMALL_4

          WR_SMALL_2   : begin
                           if(s_axis_rq_tready) begin
                             interl_en_w = (curr_mwr_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                             if(AXISTEN_IF_RQ_STRADDLE[1]) begin //STRADDLE 4
                               nxt_state = DONE;
                               //rq_done_w = 1'b1;
                             end
                             else begin //STRADDLE 2
                               if(curr_mwr_count == 0 || (interl_en && curr_mwr_wrr_cnt == 0) ) begin // last WR
                                 if (curr_mrd_count == 0) begin
                                   nxt_state = DONE;
                                   //rq_done_w = 1'b1;
                                 end
                                 else begin  
                                   nxt_state = RD_ONLY_2;
                                   curr_mrd_count_w = curr_mrd_count - 2;
                                   curr_mrd_wrr_cnt_w = (~interl_en) ? 0 : mrd_wrr_cnt_i - 2;
                                 end
                               end
                               else begin // not last WR 
                                 nxt_state = WR_SMALL_2;
                                 curr_mwr_count_w = curr_mwr_count - 2;
                                 curr_mwr_wrr_cnt_w = (~interl_en) ? 0 : curr_mwr_wrr_cnt - 2;
                               end
                             end

                             // Address counting counters:
                             w_tcnt_w            = w_tcnt + 2;

                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w   = 1'b1;
                             s_axis_rq_tlast_w    = 1'b0; // tlast/tkeep not used in STRADDLE 
                             s_axis_rq_tkeep_w    = 'd0;  // tlast/tkeep not used in STRADDLE 
                             
                             s_axis_rq_tdata_w[1023:512] = 'd0; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.d_1 = {4{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.d_0 = {4{mwr_data_i}}; // copy all data and use sop/eop to take the right part 
                             s_axis_rq_tdata_w.h_1.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_1.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_1.addr_63_2      = {32'd0, wr_addr_31_2_1};
                             s_axis_rq_tdata_w.h_0.req_type       = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_0.dword_count    = mwr_len_i;
                             s_axis_rq_tdata_w.h_0.addr_63_2      = {32'd0, wr_addr_31_2_0};
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_1.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_1[127:79]         = 'd0;
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_0.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_0[127:79]         = 'd0;

                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b0; 
                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b0; 
                             s_axis_rq_tuser_w.is_eop      = 4'b0011; 
                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b00;     
                             s_axis_rq_tuser_w.is_sop1_ptr = 2'b01;     
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b00;     
                             s_axis_rq_tuser_w.is_sop      = 4'b0011;   
                             s_axis_rq_tuser_w.last_be     = (mwr_len_i[0]) ? 16'h0 : 16'h00FF;  
                             s_axis_rq_tuser_w.first_be    = 16'h00FF;  
                             case(1'b1)
                             mwr_len_i[0]: begin //1DW
                                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b01100; // DW12 
                                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b00100; // DW4 
                                           end
                             mwr_len_i[1]: begin //2DW
                                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b01101; // DW13 
                                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b00101; // DW5 
                                           end
                             mwr_len_i[2]: begin //4DW
                                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b01111; // DW15 
                                             s_axis_rq_tuser_w.is_eop0_ptr = 5'b00111; // DW7 
                                           end
                             endcase
                           end //if(s_axis_rq_tready) begin
                         end // state WR_SMALL_2

          RD_ONLY_4    : begin
                           if(s_axis_rq_tready) begin
                             //if ( ( avail_client_tag[client_tag_assigned_num_10bit_0] 
                             //     & avail_client_tag[client_tag_assigned_num_10bit_1] 
                             //     & avail_client_tag[client_tag_assigned_num_10bit_2] 
                             //     & avail_client_tag[client_tag_assigned_num_10bit_3])
                             //    | ~AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                             if ( &next_client_tag_available[3:0] ) begin 
                               interl_en_w = (curr_mrd_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                               if(curr_mrd_count == 0) begin //last RD
                                 if(curr_mwr_count == 0) begin
                                   nxt_state = DONE;
                                   //rq_done_w = 1'b1;
                                 end
                                 else begin // only WR left
                                   curr_mwr_wrr_cnt_w = 0;
                                   case(mwr_len_case) 
                                     3'd0: begin // > 28 DW 
                                             nxt_state = WR_32DW_DW0;
                                             wr_end_case_w      = 2'd0; 
                                             curr_mwr_count_w   = curr_mwr_count - 1;
                                             curr_mwr_len_w     = mwr_len_i >> 5;
                                           end //case -> 3'd0
                                     3'd2: begin // (12,20]
                                             nxt_state = WR_16DW_DW0;
                                             curr_mwr_count_w   = curr_mwr_count - 2;
                                           end //case -> 3'd2
                                     3'd3: begin // ( 4,12] 
                                             nxt_state = WR_8DW;
                                             if(curr_mwr_count == 1) begin
                                               curr_mwr_count_w   = 0;
                                               wr_end_case_w = 2'd3;
                                             end
                                             else begin
                                               curr_mwr_count_w   = curr_mwr_count - 2;
                                               wr_end_case_w = 2'd0;
                                             end
                                           end //case -> 3'd3
                                     default: // < 4 DW 
                                           begin
                                             if (curr_mwr_count == 2) begin // Only 2 WR left
                                               nxt_state = WR_SMALL_2;
                                               curr_mwr_count_w   = curr_mwr_count - 2;
                                             end 
                                             else begin // 4 TLP straddle 
                                               nxt_state = WR_SMALL_4;
                                               curr_mwr_count_w   = mwr_count_i - 4;
                                             end 
                                           end //case -> default
                                   endcase
                                 end
                               end
                               else if(interl_en && curr_mrd_wrr_cnt == 0) begin // interleave 
                                 case(mwr_len_case) 
                                   3'd0: begin // > 28 DW 
                                           nxt_state = WR_32DW_DW0;
                                           wr_end_case_w      = 2'd0; 
                                           curr_mwr_count_w   = curr_mwr_count - 1;
                                           curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 1;
                                           curr_mwr_len_w     = mwr_len_i >> 5;
                                         end //case -> 3'd0
                                   3'd2: begin // (12,20]
                                           nxt_state = WR_16DW_DW0;
                                           curr_mwr_count_w   = curr_mwr_count - 2;
                                           curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                         end //case -> 3'd2
                                   3'd3: begin // ( 4,12] 
                                           nxt_state = WR_8DW;
                                           if(curr_mwr_count == 1) begin
                                             curr_mwr_count_w   = 0;
                                             curr_mwr_wrr_cnt_w = 0;
                                             wr_end_case_w = 2'd3;
                                           end
                                           else begin
                                             curr_mwr_count_w   = curr_mwr_count - 2;
                                             curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                             wr_end_case_w = 2'd0;
                                           end
                                         end //case -> 3'd3
                                   default: // < 4 DW 
                                         begin
                                           if (curr_mwr_count == 2 || mwr_wrr_cnt_i == 2) begin
                                               nxt_state = RAW;
                                               curr_mwr_count_w   = curr_mwr_count - 2;
                                               curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                               curr_mrd_count_w   = curr_mrd_count - 2;
                                               curr_mrd_wrr_cnt_w = mrd_wrr_cnt_i - 2;
                                           end 
                                           else begin // WR only
                                             nxt_state = WR_SMALL_4;
                                             curr_mwr_count_w   = curr_mwr_count - 4;
                                             curr_mwr_wrr_cnt_w = ~interl_en ? 0 : mwr_wrr_cnt_i - 4;
                                           end 
                                         end //case -> default
                                 endcase
                               end
                               else if(interl_en && curr_mrd_wrr_cnt == 2) begin
                                 case(mwr_len_case) 
                                   3'd0, 3'd2, 3'd3: // >= 4DW 
                                         begin 
                                           nxt_state = WAR_1HDR;
                                           curr_mrd_count_w = curr_mrd_count - 2;
                                           curr_mrd_wrr_cnt_w = 0; //curr_mrd_wrr_cnt - 2;
                                           curr_mwr_count_w = curr_mwr_count - 1;
                                           curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 1;
                                           
                                           curr_mwr_len_w = mwr_len_i >> 5;
                                         end   
                                   default: // < 4 DW 
                                         begin
                                           nxt_state = WAR_2HDR;
                                           curr_mrd_count_w = curr_mrd_count - 2;
                                           curr_mrd_wrr_cnt_w = 0; //curr_mrd_wrr_cnt - 2;
                                           curr_mwr_count_w = curr_mwr_count - 2;
                                           curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                         end //case -> default
                                 endcase
                               end
                               else if (curr_mrd_count == 2)begin
                                 nxt_state = RD_ONLY_2;
                                 curr_mrd_count_w = curr_mrd_count - 2;
                                 curr_mrd_wrr_cnt_w = 0;
                               end
                               else begin
                                 nxt_state = RD_ONLY_4;
                                 curr_mrd_count_w = curr_mrd_count - 4;
                                 curr_mrd_wrr_cnt_w = (~interl_en)? 0 :  curr_mrd_wrr_cnt - 4;
                               end
                               // Address counting counters:
                               r_tcnt_w            = r_tcnt + 4;
                               if (AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                                 client_tag_assigned_0_wire           = 1'b1;
                                 client_tag_assigned_1_wire           = 1'b1;
                                 client_tag_assigned_2_wire           = 1'b1;
                                 client_tag_assigned_3_wire           = 1'b1;
                                 client_tag_assigned_num_0_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_0, 4);
                                 client_tag_assigned_num_1_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_1, 4);
                                 client_tag_assigned_num_2_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_2, 4);
                                 client_tag_assigned_num_3_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_3, 4);
                                 s_axis_rq_tdata_w.h_0.tag            = client_tag_assigned_num_10bit_0[7:0];
                                 s_axis_rq_tdata_w.h_0.req_id_en      = client_tag_assigned_num_10bit_0[8];
                                 s_axis_rq_tdata_w.h_0.force_ecrc     = client_tag_assigned_num_10bit_0[9];
                                 s_axis_rq_tdata_w.h_1.tag            = client_tag_assigned_num_10bit_1[7:0];
                                 s_axis_rq_tdata_w.h_1.req_id_en      = client_tag_assigned_num_10bit_1[8];
                                 s_axis_rq_tdata_w.h_1.force_ecrc     = client_tag_assigned_num_10bit_1[9];
                                 s_axis_rq_tdata_w.h_2.tag            = client_tag_assigned_num_10bit_2[7:0];
                                 s_axis_rq_tdata_w.h_2.req_id_en      = client_tag_assigned_num_10bit_2[8];
                                 s_axis_rq_tdata_w.h_2.force_ecrc     = client_tag_assigned_num_10bit_2[9];
                                 s_axis_rq_tdata_w.h_3.tag            = client_tag_assigned_num_10bit_3[7:0];
                                 s_axis_rq_tdata_w.h_3.req_id_en      = client_tag_assigned_num_10bit_3[8];
                                 s_axis_rq_tdata_w.h_3.force_ecrc     = client_tag_assigned_num_10bit_3[9];
                               end
			       else begin
                                 s_axis_rq_tdata_w.h_0.tag            = 'd0; 
                                 s_axis_rq_tdata_w.h_0.req_id_en      = 'd0; 
                                 s_axis_rq_tdata_w.h_0.force_ecrc     = 'd0; 
                                 s_axis_rq_tdata_w.h_1.tag            = 'd0; 
                                 s_axis_rq_tdata_w.h_1.req_id_en      = 'd0; 
                                 s_axis_rq_tdata_w.h_1.force_ecrc     = 'd0; 
                                 s_axis_rq_tdata_w.h_2.tag            = 'd0; 
                                 s_axis_rq_tdata_w.h_2.req_id_en      = 'd0; 
                                 s_axis_rq_tdata_w.h_2.force_ecrc     = 'd0; 
                                 s_axis_rq_tdata_w.h_3.tag            = 'd0; 
                                 s_axis_rq_tdata_w.h_3.req_id_en      = 'd0; 
                                 s_axis_rq_tdata_w.h_3.force_ecrc     = 'd0; 
			       end


                                
                               //**** RQ Interface **** //
                               s_axis_rq_tvalid_w               = 1'b1;
                               s_axis_rq_tlast_w                = 1'b0;  //tlast/tkeep not used in straddle 
                               s_axis_rq_tkeep_w                = 32'h0; //tlast/tkeep not used in straddle 

                               s_axis_rq_tdata_w.d_3 = 128'd0; 
                               s_axis_rq_tdata_w.d_2 = 128'd0; 
                               s_axis_rq_tdata_w.d_1 = 128'd0; 
                               s_axis_rq_tdata_w.d_0 = 128'd0; 
                               s_axis_rq_tdata_w.h_3.req_type       = 4'b0000; // MemRd
                               s_axis_rq_tdata_w.h_3.dword_count    = mrd_len_i;
                               s_axis_rq_tdata_w.h_3.addr_63_2      = {32'd0, rd_addr_31_2_3};
                               s_axis_rq_tdata_w.h_2.req_type       = 4'b0000; // MemRd
                               s_axis_rq_tdata_w.h_2.dword_count    = mrd_len_i;
                               s_axis_rq_tdata_w.h_2.addr_63_2      = {32'd0, rd_addr_31_2_2};
                               s_axis_rq_tdata_w.h_1.req_type       = 4'b0000; // MemRd
                               s_axis_rq_tdata_w.h_1.dword_count    = mrd_len_i;
                               s_axis_rq_tdata_w.h_1.addr_63_2      = {32'd0, rd_addr_31_2_1};
                               s_axis_rq_tdata_w.h_0.req_type       = 4'b0000; // MemRd
                               s_axis_rq_tdata_w.h_0.dword_count    = mrd_len_i;
                               s_axis_rq_tdata_w.h_0.addr_63_2      = {32'd0, rd_addr_31_2_0};
                               // clear tdata to zero
                               s_axis_rq_tdata_w.h_3.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_3[95:79]          = 'd0; // req_id, poisoned_req
                               s_axis_rq_tdata_w.h_3[119:104]        = 'd0; // cmpl_id
                               s_axis_rq_tdata_w.h_3[126:121]        = 'd0; // attr, tc 
                               s_axis_rq_tdata_w.h_2.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_2[95:79]          = 'd0; // req_id, poisoned_req
                               s_axis_rq_tdata_w.h_2[119:104]        = 'd0; // cmpl_id
                               s_axis_rq_tdata_w.h_2[126:121]        = 'd0; // attr, tc 
                               s_axis_rq_tdata_w.h_1.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_1[95:79]          = 'd0; // req_id, poisoned_req
                               s_axis_rq_tdata_w.h_1[119:104]        = 'd0; // cmpl_id
                               s_axis_rq_tdata_w.h_1[126:121]        = 'd0; // attr, tc 
                               s_axis_rq_tdata_w.h_0.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_0[95:79]          = 'd0; // req_id, poisoned_req
                               s_axis_rq_tdata_w.h_0[119:104]        = 'd0; // cmpl_id
                               s_axis_rq_tdata_w.h_0[126:121]        = 'd0; // attr, tc 
                               s_axis_rq_tuser_w.is_eop3_ptr = 5'b11011;  // DW27
                               s_axis_rq_tuser_w.is_eop2_ptr = 5'b10011;  // DW19
                               s_axis_rq_tuser_w.is_eop1_ptr = 5'b01011;  // DW11
                               s_axis_rq_tuser_w.is_eop0_ptr = 5'b00011;  // DW3
                               s_axis_rq_tuser_w.is_eop      = 4'b1111;   // 
                               s_axis_rq_tuser_w.is_sop3_ptr = 2'b11;     // DW24
                               s_axis_rq_tuser_w.is_sop2_ptr = 2'b10;     // DW16
                               s_axis_rq_tuser_w.is_sop1_ptr = 2'b01;     // DW8
                               s_axis_rq_tuser_w.is_sop0_ptr = 2'b00;     // DW0
                               s_axis_rq_tuser_w.is_sop      = 4'b1111;   // 
                               s_axis_rq_tuser_w.last_be     = (mrd_len_i[0]) ? 16'h0 : 16'hFFFF;  
                               s_axis_rq_tuser_w.first_be    = 16'hFFFF;  
                             end // no available tag
			     else begin
                               client_tag_assigned_0_wire    = 1'b0;
                               client_tag_assigned_1_wire    = 1'b0;
                               client_tag_assigned_2_wire    = 1'b0;
                               client_tag_assigned_3_wire    = 1'b0;
			       waiting_for_next_tag          = 'b1;
                               s_axis_rq_tvalid_w            = 1'b0; // Pull down the valid if tag is not available
			     end
                           end //if(s_axis_rq_tready) begin
                         end // state RD_ONLY_4

          RD_ONLY_2    : begin
                           if(s_axis_rq_tready) begin
                             //if ( ( avail_client_tag[client_tag_assigned_num_10bit_0] 
                             //     & avail_client_tag[client_tag_assigned_num_10bit_1]) 
                             //    | ~AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                             if ( &next_client_tag_available[1:0] ) begin 
                               interl_en_w = (curr_mrd_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                               if(AXISTEN_IF_RQ_STRADDLE[1]) begin //STRADDLE 4
                                 nxt_state = DONE;
                                 //rq_done_w = 1'b1;
                               end

                               else begin
                                 if(curr_mrd_count == 0 || (interl_en && curr_mrd_wrr_cnt == 0)) begin
                                   if(curr_mwr_count == 0) begin
                                     nxt_state = DONE;
                                     //rq_done_w = 1'b1;
                                   end
                                   else begin 
                                     case(mwr_len_case) 
                                       3'd0: begin // > 28 DW 
                                               nxt_state = WR_32DW_DW0;
                                               wr_end_case_w      = 2'd0; 
                                               curr_mwr_count_w   = curr_mwr_count - 1;
                                               curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 1;
                                               curr_mwr_len_w     = mwr_len_i >> 5;
                                             end //case -> 3'd0
                                       3'd2: begin // (12,20]
                                               nxt_state = WR_16DW_DW0;
                                               curr_mwr_count_w   = curr_mwr_count - 2;
                                               curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                             end //case -> 3'd2
                                       3'd3: begin // ( 4,12] 
                                               nxt_state = WR_8DW;
                                               if(curr_mwr_count == 1) begin
                                                 curr_mwr_count_w   = 0;
                                                 curr_mwr_wrr_cnt_w = 0;
                                                 wr_end_case_w = 2'd3;
                                               end
                                               else begin
                                                 curr_mwr_count_w   = curr_mwr_count - 2;
                                                 curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                                 wr_end_case_w = 2'd0;
                                               end
                                             end //case -> 3'd3
                                       default: // < 4 DW 
                                             begin
                                               nxt_state = WR_SMALL_2;
                                               curr_mwr_count_w   = curr_mwr_count - 2;
                                               curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                             end //case -> default
                                     endcase
                                   end
                                 end
                                 else begin
                                   nxt_state = RD_ONLY_2;
                                   curr_mrd_count_w = curr_mrd_count - 2;
                                   curr_mrd_wrr_cnt_w = (~interl_en)? 0 :  curr_mrd_wrr_cnt - 2;
                                 end
                               
                               end
                               // Address counting counters:
                               r_tcnt_w            = r_tcnt + 2;
                               if (AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                                 client_tag_assigned_0_wire           = 1'b1;
                                 client_tag_assigned_1_wire           = 1'b1;
                                 client_tag_assigned_2_wire           = 1'b0;
                                 client_tag_assigned_3_wire           = 1'b0;
                                 client_tag_assigned_num_0_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_0, 2);
                                 client_tag_assigned_num_1_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_1, 2);
                                 client_tag_assigned_num_2_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_2, 2);
                                 client_tag_assigned_num_3_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_3, 2);
                                 s_axis_rq_tdata_w.h_0.tag            = client_tag_assigned_num_10bit_0[7:0];
                                 s_axis_rq_tdata_w.h_0.req_id_en      = client_tag_assigned_num_10bit_0[8];
                                 s_axis_rq_tdata_w.h_0.force_ecrc     = client_tag_assigned_num_10bit_0[9];
                                 s_axis_rq_tdata_w.h_1.tag            = client_tag_assigned_num_10bit_1[7:0];
                                 s_axis_rq_tdata_w.h_1.req_id_en      = client_tag_assigned_num_10bit_1[8];
                                 s_axis_rq_tdata_w.h_1.force_ecrc     = client_tag_assigned_num_10bit_1[9];
                               end
			       else begin
                                 s_axis_rq_tdata_w.h_0.tag            = 'd0; 
                                 s_axis_rq_tdata_w.h_0.req_id_en      = 'd0; 
                                 s_axis_rq_tdata_w.h_0.force_ecrc     = 'd0; 
                                 s_axis_rq_tdata_w.h_1.tag            = 'd0; 
                                 s_axis_rq_tdata_w.h_1.req_id_en      = 'd0; 
                                 s_axis_rq_tdata_w.h_1.force_ecrc     = 'd0; 
			       end


                               //**** RQ Interface **** //
                               s_axis_rq_tvalid_w               = 1'b1;
                               s_axis_rq_tlast_w                = 1'b0;  //tlast/tkeep not used in straddle 
                               s_axis_rq_tkeep_w                = 32'h0; //tlast/tkeep not used in straddle 

                               s_axis_rq_tdata_w[1023:512]          = 'd0; 
                               s_axis_rq_tdata_w.h_1.req_type       = 4'b0000; // MemRd
                               s_axis_rq_tdata_w.h_1.dword_count    = mrd_len_i;
                               s_axis_rq_tdata_w.h_1.addr_63_2      = {32'd0, rd_addr_31_2_1};
                               s_axis_rq_tdata_w.h_0.req_type       = 4'b0000; // MemRd
                               s_axis_rq_tdata_w.h_0.dword_count    = mrd_len_i;
                               s_axis_rq_tdata_w.h_0.addr_63_2      = {32'd0, rd_addr_31_2_0};
                               // clear tdata to zero
                               s_axis_rq_tdata_w.h_1.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_1[95:79]          = 'd0; // req_id, poisoned_req
                               s_axis_rq_tdata_w.h_1[119:104]        = 'd0; // cmpl_id
                               s_axis_rq_tdata_w.h_1[126:121]        = 'd0; // attr, tc 
                               s_axis_rq_tdata_w.h_0.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_0[95:79]          = 'd0; // req_id, poisoned_req
                               s_axis_rq_tdata_w.h_0[119:104]        = 'd0; // cmpl_id
                               s_axis_rq_tdata_w.h_0[126:121]        = 'd0; // attr, tc 
                               s_axis_rq_tdata_w.d_1       = 128'b0;
                               s_axis_rq_tdata_w.d_0       = 128'b0;

                               s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;  
                               s_axis_rq_tuser_w.is_eop2_ptr = 5'b00000;  
                               s_axis_rq_tuser_w.is_eop1_ptr = 5'b01011;  // DW11
                               s_axis_rq_tuser_w.is_eop0_ptr = 5'b00011;  // DW3
                               s_axis_rq_tuser_w.is_eop      = 4'b0011;   
                               s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     
                               s_axis_rq_tuser_w.is_sop2_ptr = 2'b00;     
                               s_axis_rq_tuser_w.is_sop1_ptr = 2'b01;     // DW8
                               s_axis_rq_tuser_w.is_sop0_ptr = 2'b00;     // DW0
                               s_axis_rq_tuser_w.is_sop      = 4'b0011;    
                               s_axis_rq_tuser_w.last_be     = (mrd_len_i[0]) ? 16'h0 : 16'h00FF;  
                               s_axis_rq_tuser_w.first_be    = 16'h00FF; 
                             end // no available tag
			     else begin
                               client_tag_assigned_0_wire    = 1'b0;
                               client_tag_assigned_1_wire    = 1'b0;
                               client_tag_assigned_2_wire    = 1'b0;
                               client_tag_assigned_3_wire    = 1'b0;
			       waiting_for_next_tag          = 'b1;
                               s_axis_rq_tvalid_w            = 1'b0; // Pull down the valid if tag is not available
			     end
                           end //if(s_axis_rq_tready) begin
                         end // state RD_ONLY_2

          RAW          : begin // SAME logic as RD_ONLY_4
                           if(s_axis_rq_tready) begin
                             //if ( ( avail_client_tag[client_tag_assigned_num_10bit_0] 
                             //     & avail_client_tag[client_tag_assigned_num_10bit_1]) 
                             //    | ~AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                             if ( &next_client_tag_available[1:0] ) begin 
                               interl_en_w = (curr_mrd_count == 0 || curr_mwr_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                               if(curr_mrd_count == 0) begin
                                 if(curr_mwr_count == 0) begin
                                   nxt_state = DONE; 
                                   //rq_done_w = 1'b1;
                                 end
                                 else begin // only WR left
                                   curr_mwr_wrr_cnt_w = 0;
                                   case(mwr_len_case) 
                                     3'd0: begin // > 28 DW 
                                             nxt_state = WR_32DW_DW0;
                                             wr_end_case_w      = 2'd0; 
                                             curr_mwr_count_w   = curr_mwr_count - 1;
                                             curr_mwr_len_w     = mwr_len_i >> 5;
                                           end //case -> 3'd0
                                     3'd2: begin // (12,20]
                                             nxt_state = WR_16DW_DW0;
                                             curr_mwr_count_w   = curr_mwr_count - 2;
                                           end //case -> 3'd2
                                     3'd3: begin // ( 4,12] 
                                             nxt_state = WR_8DW;
                                             if(curr_mwr_count == 1) begin
                                               curr_mwr_count_w   = 0;
                                               wr_end_case_w = 2'd3;
                                             end
                                             else begin
                                               curr_mwr_count_w   = curr_mwr_count - 2;
                                               wr_end_case_w = 2'd0;
                                             end
                                           end //case -> 3'd3
                                     default: // < 4 DW 
                                           begin
                                             if (curr_mwr_count == 2) begin // Only 2 WR left
                                               nxt_state = WR_SMALL_2;
                                               curr_mwr_count_w   = curr_mwr_count - 2;
                                             end 
                                             else begin // 4 TLP straddle 
                                               nxt_state = WR_SMALL_4;
                                               curr_mwr_count_w   = curr_mwr_count - 4;
                                             end 
                                           end //case -> default
                                   endcase
                                 end
                               end
                               else if(curr_mwr_count != 0 && curr_mrd_wrr_cnt == 0) begin
                                 case(mwr_len_case) 
                                   3'd0: begin // > 28 DW 
                                           nxt_state = WR_32DW_DW0;
                                           wr_end_case_w      = 2'd0; 
                                           curr_mwr_count_w   = curr_mwr_count - 1;
                                           curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 1;
                                           curr_mwr_len_w     = mwr_len_i >> 5;
                                         end //case -> 3'd0
                                   3'd2: begin // (12,20]
                                           nxt_state = WR_16DW_DW0;
                                           curr_mwr_count_w   = curr_mwr_count - 2;
                                           curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                         end //case -> 3'd2
                                   3'd3: begin // ( 4,12] 
                                           nxt_state = WR_8DW;
                                           if(curr_mwr_count == 1) begin
                                             curr_mwr_count_w   = 0;
                                             curr_mwr_wrr_cnt_w = 0;
                                             wr_end_case_w = 2'd3;
                                           end
                                           else begin
                                             curr_mwr_count_w   = curr_mwr_count - 2;
                                             curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                             wr_end_case_w = 2'd0;
                                           end
                                         end //case -> 3'd3
                                   default: // < 4 DW 
                                         begin
                                           if (curr_mwr_count == 2 || mwr_wrr_cnt_i == 2) begin
                                               nxt_state = RAW;
                                               curr_mwr_count_w   = curr_mwr_count - 2;
                                               curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                               curr_mrd_count_w   = curr_mrd_count - 2;
                                               curr_mrd_wrr_cnt_w = mrd_wrr_cnt_i - 2;
                                           end 
                                           else begin // WR only
                                             nxt_state = WR_SMALL_4;
                                             curr_mwr_count_w   = curr_mwr_count - 4;
                                             curr_mwr_wrr_cnt_w = ~interl_en ? 0 : mwr_wrr_cnt_i - 4;
                                           end 
                                         end //case -> default
                                 endcase
                               end
                               else if(curr_mwr_count != 0 && curr_mrd_wrr_cnt == 2) begin
                                 case(mwr_len_case) 
                                   3'd0, 3'd2, 3'd3: // >= 4DW 
                                         begin 
                                           nxt_state = WAR_1HDR;
                                           curr_mrd_count_w = curr_mrd_count - 2;
                                           curr_mrd_wrr_cnt_w = 0; //curr_mrd_wrr_cnt - 2;
                                           curr_mwr_count_w = curr_mwr_count - 1;
                                           curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 1;
                                           if(mwr_len_case == 3'd0) begin
                                             curr_mwr_len_w = mwr_len_i >> 5;
                                             wr_end_case_w = 2'd2; 
                                           end
                                         end   
                                   default: // < 4 DW 
                                         begin
                                           nxt_state = WAR_2HDR;
                                           curr_mrd_count_w = curr_mrd_count - 2;
                                           curr_mrd_wrr_cnt_w = 0; //curr_mrd_wrr_cnt - 2;
                                           curr_mwr_count_w = curr_mwr_count - 2;
                                           curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                         end //case -> default
                                 endcase
                               end
                               else if (curr_mrd_count == 2)begin
                                 nxt_state = RD_ONLY_2;
                                 curr_mrd_count_w = curr_mrd_count - 2;
                                 curr_mrd_wrr_cnt_w = 0;
                               end
                               else begin
                                 nxt_state = RD_ONLY_4;
                                 curr_mrd_count_w = curr_mrd_count - 4;
                                 curr_mrd_wrr_cnt_w = (~interl_en)? 0 :  curr_mrd_wrr_cnt - 4;
                               end

                               // Address counting counters:
                               w_tcnt_w            = mwr_len_i[3] ? w_tcnt + 1 : (|mwr_len_i[2:0] ? w_tcnt + 2 : w_tcnt);
                               r_tcnt_w            = r_tcnt + 2;

                               if (AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                                 client_tag_assigned_0_wire           = 1'b1;
                                 client_tag_assigned_1_wire           = 1'b1;
                                 client_tag_assigned_num_0_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_0, 2);
                                 client_tag_assigned_num_1_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_1, 2);
                                 client_tag_assigned_num_2_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_2, 2);
                                 client_tag_assigned_num_3_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_3, 2);
                                 s_axis_rq_tdata_w.h_2.tag            = client_tag_assigned_num_10bit_0[7:0];
                                 s_axis_rq_tdata_w.h_2.req_id_en      = client_tag_assigned_num_10bit_0[8];
                                 s_axis_rq_tdata_w.h_2.force_ecrc     = client_tag_assigned_num_10bit_0[9];
                                 s_axis_rq_tdata_w.h_3.tag            = client_tag_assigned_num_10bit_1[7:0];
                                 s_axis_rq_tdata_w.h_3.req_id_en      = client_tag_assigned_num_10bit_1[8];
                                 s_axis_rq_tdata_w.h_3.force_ecrc     = client_tag_assigned_num_10bit_1[9];
                               end
			       else begin
                                 s_axis_rq_tdata_w.h_2.tag            = 'd0; 
                                 s_axis_rq_tdata_w.h_2.req_id_en      = 'd0; 
                                 s_axis_rq_tdata_w.h_2.force_ecrc     = 'd0; 
                                 s_axis_rq_tdata_w.h_3.tag            = 'd0; 
                                 s_axis_rq_tdata_w.h_3.req_id_en      = 'd0; 
                                 s_axis_rq_tdata_w.h_3.force_ecrc     = 'd0; 
			       end


                               //**** RQ Interface **** //
                               s_axis_rq_tvalid_w               = 1'b1;
                               s_axis_rq_tlast_w                = 1'b0;  //tlast/tkeep not used in straddle 
                               s_axis_rq_tkeep_w                = 32'h0; //tlast/tkeep not used in straddle 

                               s_axis_rq_tdata_w.d_3      = 128'd0; 
                               s_axis_rq_tdata_w.d_2      = 128'd0; 
                               s_axis_rq_tdata_w.h_3.req_type       = 4'b0000; // MemRd
                               s_axis_rq_tdata_w.h_3.dword_count    = mrd_len_i;
                               s_axis_rq_tdata_w.h_3.addr_63_2      = {32'd0, rd_addr_31_2_1};
                               s_axis_rq_tdata_w.h_2.req_type       = 4'b0000; // MemRd
                               s_axis_rq_tdata_w.h_2.dword_count    = mrd_len_i;
                               s_axis_rq_tdata_w.h_2.addr_63_2      = {32'd0, rd_addr_31_2_0};
                               // clear tdata to zero
                               s_axis_rq_tdata_w.h_3.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_3[95:79]          = 'd0; // req_id, poisoned_req
                               s_axis_rq_tdata_w.h_3[119:104]        = 'd0; // cmpl_id
                               s_axis_rq_tdata_w.h_3[126:121]        = 'd0; // attr, tc 
                               s_axis_rq_tdata_w.h_2.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_2[95:79]          = 'd0; // req_id, poisoned_req
                               s_axis_rq_tdata_w.h_2[119:104]        = 'd0; // cmpl_id
                               s_axis_rq_tdata_w.h_2[126:121]        = 'd0; // attr, tc 

                               case(1'b1)
                                |mwr_len_i[2:0] : begin // 1,2,4 DW WR
                                                  s_axis_rq_tdata_w.d_1             = {4{mwr_data_i}}; 
                                                  s_axis_rq_tdata_w.d_0             = {4{mwr_data_i}}; 
                                                  s_axis_rq_tdata_w.h_1.req_type    = 4'b0001; // MemWr
                                                  s_axis_rq_tdata_w.h_1.dword_count = mwr_len_i;
                                                  s_axis_rq_tdata_w.h_1.addr_63_2   = {32'd0, wr_addr_31_2_1};
                                                  s_axis_rq_tdata_w.h_0.req_type    = 4'b0001; // MemWr
                                                  s_axis_rq_tdata_w.h_0.dword_count = mwr_len_i;
                                                  s_axis_rq_tdata_w.h_0.addr_63_2   = {32'd0, wr_addr_31_2_0};
                                                  // clear tdata to zero
                                                  s_axis_rq_tdata_w.h_1.addr_type       = 2'b0;
                                                  s_axis_rq_tdata_w.h_1[127:79]         = 'd0;
                                                  s_axis_rq_tdata_w.h_0.addr_type       = 2'b0;
                                                  s_axis_rq_tdata_w.h_0[127:79]         = 'd0;
                                                  s_axis_rq_tuser_w.is_sop3_ptr = 2'b11; 
                                                  s_axis_rq_tuser_w.is_sop2_ptr = 2'b10; 
                                                  s_axis_rq_tuser_w.is_sop1_ptr = 2'b01; 
                                                  s_axis_rq_tuser_w.is_sop0_ptr = 2'b00; 
                                                  s_axis_rq_tuser_w.is_sop      = 4'b1111; 
                                                  s_axis_rq_tuser_w.is_eop3_ptr = 5'b11011; // RD ends DW 27
                                                  s_axis_rq_tuser_w.is_eop2_ptr = 5'b10011; // RD ends DW 19
                                                  s_axis_rq_tuser_w.is_eop1_ptr = {3'b011, mwr_len_i[2], ~mwr_len_i[0]}; // {1,2,4}DW ends @ DW{12,13,15}   
                                                  s_axis_rq_tuser_w.is_eop0_ptr = {3'b001, mwr_len_i[2], ~mwr_len_i[0]}; // {1,2,4}DW ends @ DW{ 4, 5, 7}   
                                                  s_axis_rq_tuser_w.is_eop      = 4'b1111;  
                                                  s_axis_rq_tuser_w.last_be[15:8] = mrd_len_i[0] ? 8'h0 : 8'hFF; 
                                                  s_axis_rq_tuser_w.last_be[ 7:0] = mwr_len_i[0] ? 8'h0 : 8'hFF; 
                                                  s_axis_rq_tuser_w.first_be    = 16'hFFFF; 
                                                end // 1 DW
                                 mwr_len_i[3] : // 8 DW
                                                begin 
                                                  s_axis_rq_tdata_w[511:128]        = {12{mwr_data_i}}; // MemWr
                                                  s_axis_rq_tdata_w.h_0.req_type    = 4'b0000; // MemWr
                                                  s_axis_rq_tdata_w.h_0.dword_count = mwr_len_i;
                                                  s_axis_rq_tdata_w.h_0.addr_63_2   = {32'd0, wr_addr_31_2_0};
                                                  // clear tdata to zero
                                                  s_axis_rq_tdata_w.h_0.addr_type       = 2'b0;
                                                  s_axis_rq_tdata_w.h_0[127:79]         = 'd0;
                                                  s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;  
                                                  s_axis_rq_tuser_w.is_eop2_ptr = 5'b11011; // DW 27 
                                                  s_axis_rq_tuser_w.is_eop1_ptr = 5'b10011; // DW 19
                                                  s_axis_rq_tuser_w.is_eop0_ptr = 5'b01011; // DW 11
                                                  s_axis_rq_tuser_w.is_eop      = 4'b0111;  // 1WR + 2RD eop  
                                                  s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     
                                                  s_axis_rq_tuser_w.is_sop2_ptr = 2'b11 ;   // DW24
                                                  s_axis_rq_tuser_w.is_sop1_ptr = 2'b10 ;   // DW16
                                                  s_axis_rq_tuser_w.is_sop0_ptr = 2'b00 ;   // DW0 
                                                  s_axis_rq_tuser_w.is_sop      = 4'b0111;  // 8DW -> WR sop + 2 RD sop    
                                                  s_axis_rq_tuser_w.last_be     = mrd_len_i[0] ? 16'hF : 16'hFFF; 
                                                  s_axis_rq_tuser_w.first_be    = 16'h0FFF; // 3 sop 
                                                end // 8 DW
                                |mwr_len_i[10:4] : // >= 16 DW
                                                begin 
                                                  s_axis_rq_tdata_w[511:0]      = {16{mwr_data_i}}; // MemWr
                                                  s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;  
                                                  s_axis_rq_tuser_w.is_eop2_ptr = 5'b11011; // DW 27 
                                                  s_axis_rq_tuser_w.is_eop1_ptr = 5'b10011; // DW 19
                                                  s_axis_rq_tuser_w.is_eop0_ptr = 5'b01011; // DW 11
                                                  s_axis_rq_tuser_w.is_eop      = 4'b0111;  // 1WR + 2RD eop  
                                                  s_axis_rq_tuser_w.is_sop3_ptr = 2'b00;     
                                                  s_axis_rq_tuser_w.is_sop2_ptr = 2'b00;     
                                                  s_axis_rq_tuser_w.is_sop1_ptr = 2'b11;    // DW24
                                                  s_axis_rq_tuser_w.is_sop0_ptr = 2'b10;    // DW16
                                                  s_axis_rq_tuser_w.is_sop      = 4'b0011;  // 2 RD sop    
                                                  s_axis_rq_tuser_w.last_be     = mrd_len_i[0] ? 16'h0 : 16'h0FF; // sop are for read 
                                                  s_axis_rq_tuser_w.first_be    = 16'h00FF; // 2 sop
                                                end // >= 16 DW
                               endcase
                             end // no available tag
			     else begin
                               client_tag_assigned_0_wire    = 1'b0;
                               client_tag_assigned_1_wire    = 1'b0;
                               client_tag_assigned_2_wire    = 1'b0;
                               client_tag_assigned_3_wire    = 1'b0;
			       waiting_for_next_tag          = 'b1;
                               s_axis_rq_tvalid_w            = 1'b0; // Pull down the valid if tag is not available
			     end
                           end //if(s_axis_rq_tready) begin
                         end // state RAW

          WAR_1HDR     : begin //RD ends here and 1 WR starts -> next beat must start with WR 
                           if(s_axis_rq_tready) begin
                             //if ( ( avail_client_tag[client_tag_assigned_num_10bit_0] 
                             //     & avail_client_tag[client_tag_assigned_num_10bit_1]) 
                             //    | ~AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                             if ( &next_client_tag_available[1:0] ) begin 
                               interl_en_w = (curr_mrd_count == 0 || curr_mwr_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                               case(mwr_len_case) 
                                 3'd0: begin // > 28 DW 
                                         if(curr_mwr_len > 1) begin
                                           nxt_state = WR_32DW_DATA;
                                           curr_mwr_len_w = curr_mwr_len - 1;
                                         end
                                         else begin
                                           nxt_state = WR_32DW_DW24;
                                           wr_end_case_w      = 2'd3; 
                                           curr_mwr_count_w   = curr_mwr_count - 1;
                                           curr_mwr_wrr_cnt_w = curr_mwr_wrr_cnt - 1;
                                         end
                                       end //case -> 3'd0
                                 3'd2: begin // (12,20]
                                         nxt_state = WR_16DW_DW8;
                                         curr_mwr_count_w   = curr_mwr_count - 1;
                                         curr_mwr_wrr_cnt_w = curr_mwr_wrr_cnt - 1;
                                       end //case -> 3'd2
                                 default: 
                                       begin // ( 4,12] 
                                         if(curr_mwr_count == 1) begin
                                           nxt_state = (curr_mrd_count == 0) ? WR_8DW : RAW;
                                           curr_mwr_count_w   = 0;
                                           curr_mwr_wrr_cnt_w = 0;
                                           curr_mrd_count_w   = (curr_mrd_count == 0) ? 0 : curr_mrd_count - 2;
                                           curr_mrd_wrr_cnt_w = (curr_mrd_count == 0) ? 0 : mrd_wrr_cnt_i - 2;
                                           wr_end_case_w = 2'd3;
                                         end
                                         else begin
                                           nxt_state = WR_8DW;
                                           curr_mwr_count_w   = curr_mwr_count - 2;
                                           curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                           wr_end_case_w = 2'd0;
                                         end
                                       end //case -> 3'd3
                               endcase

                               // Address counting counters:
                               w_tcnt_w            = w_tcnt + 1;
                               r_tcnt_w            = r_tcnt + 2;

                               if (AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                                 client_tag_assigned_0_wire           = 1'b1;
                                 client_tag_assigned_1_wire           = 1'b1;
                                 client_tag_assigned_num_0_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_0, 2);
                                 client_tag_assigned_num_1_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_1, 2);
                                 client_tag_assigned_num_2_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_2, 2);
                                 client_tag_assigned_num_3_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_3, 2);
                                 s_axis_rq_tdata_w.h_0.tag            = client_tag_assigned_num_10bit_0[7:0];
                                 s_axis_rq_tdata_w.h_0.req_id_en      = client_tag_assigned_num_10bit_0[8];
                                 s_axis_rq_tdata_w.h_0.force_ecrc     = client_tag_assigned_num_10bit_0[9];
                                 s_axis_rq_tdata_w.h_1.tag            = client_tag_assigned_num_10bit_1[7:0];
                                 s_axis_rq_tdata_w.h_1.req_id_en      = client_tag_assigned_num_10bit_1[8];
                                 s_axis_rq_tdata_w.h_1.force_ecrc     = client_tag_assigned_num_10bit_1[9];
                               end
			       else begin
                                 s_axis_rq_tdata_w.h_0.tag            = 'd0; 
                                 s_axis_rq_tdata_w.h_0.req_id_en      = 'd0; 
                                 s_axis_rq_tdata_w.h_0.force_ecrc     = 'd0; 
                                 s_axis_rq_tdata_w.h_1.tag            = 'd0; 
                                 s_axis_rq_tdata_w.h_1.req_id_en      = 'd0; 
                                 s_axis_rq_tdata_w.h_1.force_ecrc     = 'd0; 
			       end

                               //**** RQ Interface **** //
                               s_axis_rq_tvalid_w               = 1'b1;
                               s_axis_rq_tlast_w                = 1'b0;  //tlast/tkeep not used in straddle 
                               s_axis_rq_tkeep_w                = 32'h0; //tlast/tkeep not used in straddle 

                               s_axis_rq_tdata_w[1023:640]       = {12{mwr_data_i}}; 
                               s_axis_rq_tdata_w.d_1             = 128'd0; 
                               s_axis_rq_tdata_w.d_0             = 128'd0; 

                               s_axis_rq_tdata_w.h_2.req_type    = 4'b0001; // MemWr
                               s_axis_rq_tdata_w.h_2.dword_count = mwr_len_i;
                               s_axis_rq_tdata_w.h_2.addr_63_2   = {32'd0, wr_addr_31_2_0}; 
                               s_axis_rq_tdata_w.h_1.req_type    = 4'b0000; // MemRd
                               s_axis_rq_tdata_w.h_1.dword_count = mrd_len_i;
                               s_axis_rq_tdata_w.h_1.addr_63_2   = {32'd0, rd_addr_31_2_1}; 
                               s_axis_rq_tdata_w.h_0.req_type    = 4'b0000; // MemRd
                               s_axis_rq_tdata_w.h_0.dword_count = mrd_len_i;
                               s_axis_rq_tdata_w.h_0.addr_63_2   = {32'd0, rd_addr_31_2_0}; 
                               // clear tdata to zero
                               s_axis_rq_tdata_w.h_2.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_2[127:79]         = 'd0;
                               s_axis_rq_tdata_w.h_1.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_1[95:79]          = 'd0; // req_id, poisoned_req
                               s_axis_rq_tdata_w.h_1[119:104]        = 'd0; // cmpl_id
                               s_axis_rq_tdata_w.h_1[126:121]        = 'd0; // attr, tc 
                               s_axis_rq_tdata_w.h_0.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_0[95:79]          = 'd0; // req_id, poisoned_req
                               s_axis_rq_tdata_w.h_0[119:104]        = 'd0; // cmpl_id
                               s_axis_rq_tdata_w.h_0[126:121]        = 'd0; // attr, tc 

                               s_axis_rq_tuser_w.is_sop3_ptr = 2'b00; 
                               s_axis_rq_tuser_w.is_sop2_ptr = 2'b10; 
                               s_axis_rq_tuser_w.is_sop1_ptr = 2'b01; 
                               s_axis_rq_tuser_w.is_sop0_ptr = 2'b00; 
                               s_axis_rq_tuser_w.is_sop      = 4'b0111; 
                               s_axis_rq_tuser_w.last_be     = mrd_len_i[0] ? 16'h0F00 : 16'h0FFF; //WR must > 1DW 
                               s_axis_rq_tuser_w.first_be    = 16'h0FFF; 
                               s_axis_rq_tuser_w.is_eop3_ptr = 5'b00000;
                               s_axis_rq_tuser_w.is_eop2_ptr = mwr_len_i[3] ? 5'b11011 : 5'b0; // DW27
                               s_axis_rq_tuser_w.is_eop1_ptr = 5'b01011;
                               s_axis_rq_tuser_w.is_eop0_ptr = 5'b00011;
                               s_axis_rq_tuser_w.is_eop      = mwr_len_i[3] ? 4'b0111 : 4'b0011;  
                             end // no available tag
			     else begin
                               client_tag_assigned_0_wire    = 1'b0;
                               client_tag_assigned_1_wire    = 1'b0;
                               client_tag_assigned_2_wire    = 1'b0;
                               client_tag_assigned_3_wire    = 1'b0;
			       waiting_for_next_tag          = 'b1;
                               s_axis_rq_tvalid_w            = 1'b0; // Pull down the valid if tag is not available
			     end
                           end //if(s_axis_rq_tready) begin
                         end // state WAR_1HDR

          WAR_2HDR     : begin // only when WR < 4DW
                           if(s_axis_rq_tready) begin
                             //if ( ( avail_client_tag[client_tag_assigned_num_10bit_0] 
                             //     & avail_client_tag[client_tag_assigned_num_10bit_1]) 
                             //    | ~AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                             if ( &next_client_tag_available[1:0] ) begin 
                               interl_en_w = (curr_mwr_count == 0 | curr_mrd_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                               if(curr_mwr_count == 0) begin // last WR
                                 if(curr_mrd_count == 0) begin
                                   nxt_state = DONE;
                                   //rq_done_w = 1'b1;
                                 end
                                 else begin // only read left
                                   curr_mrd_wrr_cnt_w = 0;
                                   if(curr_mwr_count == 2) begin
                                     nxt_state = RD_ONLY_2;
                                     curr_mrd_count_w = curr_mrd_count - 2;
                                   end
                                   else begin
                                     nxt_state = RD_ONLY_4;
                                     curr_mrd_count_w = curr_mrd_count - 4;
                                   end
                                 end
                               end
                               else if(curr_mrd_count == 0) begin // only write left
                                 if(curr_mwr_count == 2) begin
                                   nxt_state = WR_SMALL_2;
                                   curr_mwr_count_w = 0;
                                   curr_mwr_wrr_cnt_w = 0;
                                 end
                                 else begin
                                   nxt_state = WR_SMALL_4;
                                   curr_mwr_count_w = curr_mwr_count - 4;
                                   curr_mwr_wrr_cnt_w = 0;
                                 end
                               end
                               // Interleave still ON: both RD & WR has packets left
                               else if (curr_mwr_wrr_cnt == 0) begin // last interl WR 
                                 if(curr_mrd_count == 2 || mrd_wrr_cnt_i == 2) begin
                                   nxt_state = WAR_2HDR;
                                   curr_mrd_count_w = 0;
                                   curr_mrd_wrr_cnt_w = 0;
                                   curr_mwr_count_w = curr_mwr_count - 2;
                                   curr_mwr_wrr_cnt_w = 0;
                                 end
                                 else begin
                                   nxt_state = RD_ONLY_4;
                                   curr_mrd_count_w = curr_mrd_count - 4;
                                   curr_mrd_wrr_cnt_w = mrd_wrr_cnt_i - 4;
                                 end
                               end
                               else if (curr_mwr_wrr_cnt == 2) begin // 2 interl WR left 
                                 nxt_state = RAW;
                                 curr_mwr_count_w   = curr_mwr_count - 2;
                                 curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 2;
                                 curr_mrd_count_w   = curr_mrd_count - 2;
                                 curr_mrd_wrr_cnt_w = mrd_wrr_cnt_i - 2;
                               end
                               else begin // more than 2 interl WR left
                                 nxt_state = WR_SMALL_4;
                                 curr_mwr_count_w   = curr_mwr_count - 4;
                                 curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 4;
                               end

                               // Address counting counters:
                               w_tcnt_w            = w_tcnt + 2;
                               r_tcnt_w            = r_tcnt + 2;
 
                               if (AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                                 client_tag_assigned_0_wire           = 1'b1;
                                 client_tag_assigned_1_wire           = 1'b1;
                                 client_tag_assigned_num_0_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_0, 2);
                                 client_tag_assigned_num_1_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_1, 2);
                                 client_tag_assigned_num_2_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_2, 2);
                                 client_tag_assigned_num_3_wire       = incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_3, 2);
                                 s_axis_rq_tdata_w.h_0.tag            = client_tag_assigned_num_10bit_0[7:0];
                                 s_axis_rq_tdata_w.h_0.req_id_en      = client_tag_assigned_num_10bit_0[8];
                                 s_axis_rq_tdata_w.h_0.force_ecrc     = client_tag_assigned_num_10bit_0[9];
                                 s_axis_rq_tdata_w.h_1.tag            = client_tag_assigned_num_10bit_1[7:0];
                                 s_axis_rq_tdata_w.h_1.req_id_en      = client_tag_assigned_num_10bit_1[8];
                                 s_axis_rq_tdata_w.h_1.force_ecrc     = client_tag_assigned_num_10bit_1[9];
                               end
			       else begin
                                 s_axis_rq_tdata_w.h_0.tag            = 'd0; 
                                 s_axis_rq_tdata_w.h_0.req_id_en      = 'd0; 
                                 s_axis_rq_tdata_w.h_0.force_ecrc     = 'd0; 
                                 s_axis_rq_tdata_w.h_1.tag            = 'd0; 
                                 s_axis_rq_tdata_w.h_1.req_id_en      = 'd0; 
                                 s_axis_rq_tdata_w.h_1.force_ecrc     = 'd0; 
			       end



                               //**** RQ Interface **** //
                               s_axis_rq_tvalid_w               = 1'b1;
                               s_axis_rq_tlast_w                = 1'b0;  //tlast/tkeep not used in straddle 
                               s_axis_rq_tkeep_w                = 32'h0; //tlast/tkeep not used in straddle 

                               s_axis_rq_tdata_w.d_3             = {4{mwr_data_i}}; 
                               s_axis_rq_tdata_w.d_2             = {4{mwr_data_i}}; 
                               s_axis_rq_tdata_w.d_1             = 128'd0; 
                               s_axis_rq_tdata_w.d_0             = 128'd0; 

                               s_axis_rq_tdata_w.h_3.req_type    = 4'b0001; // MemWr
                               s_axis_rq_tdata_w.h_3.dword_count = mwr_len_i;
                               s_axis_rq_tdata_w.h_3.addr_63_2   = {32'd0, wr_addr_31_2_1};
                               s_axis_rq_tdata_w.h_2.req_type    = 4'b0001; // MemWr     
                               s_axis_rq_tdata_w.h_2.dword_count = mwr_len_i;            
                               s_axis_rq_tdata_w.h_2.addr_63_2   = {32'd0, wr_addr_31_2_0};
                               s_axis_rq_tdata_w.h_1.req_type    = 4'b0000; // MemRd
                               s_axis_rq_tdata_w.h_1.dword_count = mrd_len_i;
                               s_axis_rq_tdata_w.h_1.addr_63_2   = {32'd0, rd_addr_31_2_1};
                               s_axis_rq_tdata_w.h_0.req_type    = 4'b0000; // MemRd
                               s_axis_rq_tdata_w.h_0.dword_count = mrd_len_i;
                               s_axis_rq_tdata_w.h_0.addr_63_2   = {32'd0, rd_addr_31_2_0};
                               // clear tdata to zero
                               s_axis_rq_tdata_w.h_3.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_3[127:79]         = 'd0;
                               s_axis_rq_tdata_w.h_2.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_2[127:79]         = 'd0;
                               s_axis_rq_tdata_w.h_1.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_1[95:79]          = 'd0; // req_id, poisoned_req
                               s_axis_rq_tdata_w.h_1[119:104]        = 'd0; // cmpl_id
                               s_axis_rq_tdata_w.h_1[126:121]        = 'd0; // attr, tc 
                               s_axis_rq_tdata_w.h_0.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_0[95:79]          = 'd0; // req_id, poisoned_req
                               s_axis_rq_tdata_w.h_0[119:104]        = 'd0; // cmpl_id
                               s_axis_rq_tdata_w.h_0[126:121]        = 'd0; // attr, tc 

                               s_axis_rq_tuser_w.is_sop3_ptr = 2'b11; 
                               s_axis_rq_tuser_w.is_sop2_ptr = 2'b10; 
                               s_axis_rq_tuser_w.is_sop1_ptr = 2'b01; 
                               s_axis_rq_tuser_w.is_sop0_ptr = 2'b00; 
                               s_axis_rq_tuser_w.is_sop      = 4'b1111; 
                               s_axis_rq_tuser_w.is_eop3_ptr = {3'b111, mwr_len_i[2], ~mwr_len_i[0]}; // {1,2,4}DW ends @ DW{28,29,31} 
                               s_axis_rq_tuser_w.is_eop2_ptr = {3'b101, mwr_len_i[2], ~mwr_len_i[0]}; // {1,2,4}DW ends @ DW{20,21,23} 
                               s_axis_rq_tuser_w.is_eop1_ptr = 5'b01011; //DW11
                               s_axis_rq_tuser_w.is_eop0_ptr = 5'b00011; //DW3
                               s_axis_rq_tuser_w.is_eop      = 4'b1111;  
                               s_axis_rq_tuser_w.last_be[15:8] = mwr_len_i[0] ? 8'h0 : 8'hFF; 
                               s_axis_rq_tuser_w.last_be[ 7:0] = mrd_len_i[0] ? 8'h0 : 8'hFF; 
                               s_axis_rq_tuser_w.first_be    = 16'hFFFF; 
                             end // no available tag
			     else begin
                               client_tag_assigned_0_wire    = 1'b0;
                               client_tag_assigned_1_wire    = 1'b0;
                               client_tag_assigned_2_wire    = 1'b0;
                               client_tag_assigned_3_wire    = 1'b0;
			       waiting_for_next_tag          = 'b1;
                               s_axis_rq_tvalid_w            = 1'b0; // Pull down the valid if tag is not available
			     end
                           end //if(s_axis_rq_tready) begin
                         end // state WAR_2HDR

          // NO-STRADDLE
          WR_HEADER    : begin
                           if(s_axis_rq_tready) begin
                             interl_en_w = (curr_mwr_count == 0 | curr_mrd_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                             if(mwr_len_i > 28) begin // Need more beats
                               nxt_state = WR_DATA;
                               curr_mwr_len_w = curr_mwr_len - 1; // counting multiple of 32 for rest data
                             end
                             else begin // finish within 1 beat
                               if(curr_mwr_count == 0) begin // last write packet
                                 if(curr_mrd_count != 0) begin // read packet following
                                   nxt_state = RD;
                                   curr_mrd_count_w = curr_mrd_count - 1;
                                   curr_mrd_wrr_cnt_w = 0;
                                 end
                                 else begin // no read packet
                                   nxt_state = DONE;
                                   //rq_done_w = 1'b1;
                                 end
                               end
                               else if (interl_en && curr_mwr_wrr_cnt == 0) begin // last interl WR
                                 nxt_state = RD;
                                 curr_mrd_count_w = curr_mrd_count - 1;
                                 curr_mrd_wrr_cnt_w = mrd_wrr_cnt_i - 1;
                               end
                               else begin // not last write
                                 nxt_state = WR_HEADER;
                                 curr_mwr_count_w = curr_mwr_count - 1;
                                 curr_mwr_wrr_cnt_w = curr_mwr_wrr_cnt - 1;
                               end
                             end

                             // Address counting counters:
                             w_tcnt_w            = w_tcnt + 1;

                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w               = 1'b1;
                             s_axis_rq_tlast_w                = (mwr_len_i[4:0]) ? 1'b1 : 1'b0; 
                             case(1'b1)
                               mwr_len_i[0] : s_axis_rq_tkeep_w = 32'h1F;       //DW4
                               mwr_len_i[1] : s_axis_rq_tkeep_w = 32'h3F;       //DW5 
                               mwr_len_i[2] : s_axis_rq_tkeep_w = 32'hFF;       //DW7 
                               mwr_len_i[3] : s_axis_rq_tkeep_w = 32'hFFF;      //DW11 
                               mwr_len_i[4] : s_axis_rq_tkeep_w = 32'hFFFFF;    //DW19
                               default      : s_axis_rq_tkeep_w = 32'hFFFFFFFF; //all data are valid
                             endcase

                             s_axis_rq_tdata_w[1023:128]       = {28{mwr_data_i}}; 
                             s_axis_rq_tdata_w.h_0.req_type    = 4'b0001; // MemWr
                             s_axis_rq_tdata_w.h_0.dword_count = mwr_len_i;
                             s_axis_rq_tdata_w.h_0.addr_63_2   = {32'd0, wr_addr_31_2_0};
                             // clear tdata to zero
                             s_axis_rq_tdata_w.h_0.addr_type       = 2'b0;
                             s_axis_rq_tdata_w.h_0[127:79]         = 'd0;

                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b00; 
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b00; 
                             s_axis_rq_tuser_w.is_sop1_ptr = 2'b00; 
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b00; 
                             s_axis_rq_tuser_w.is_sop      = 4'b0000; 
                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b0;
                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b0;
                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b0;
                             s_axis_rq_tuser_w.is_eop      = (|mwr_len_i[4:0]) ? 4'b0001 : 4'b0;  
                             s_axis_rq_tuser_w.last_be     = mwr_len_i[0] ? 16'h0 : 16'h000F; 
                             s_axis_rq_tuser_w.first_be    = 16'h000F; 
                             case(1'b1)
                               mwr_len_i[0] : s_axis_rq_tuser_w.is_eop0_ptr = 5'b00100; //DW4
                               mwr_len_i[1] : s_axis_rq_tuser_w.is_eop0_ptr = 5'b00101; //DW5 
                               mwr_len_i[2] : s_axis_rq_tuser_w.is_eop0_ptr = 5'b00111; //DW7 
                               mwr_len_i[3] : s_axis_rq_tuser_w.is_eop0_ptr = 5'b01011; //DW11 
                               mwr_len_i[4] : s_axis_rq_tuser_w.is_eop0_ptr = 5'b10011; //DW19
                               default      : s_axis_rq_tuser_w.is_eop0_ptr = 5'b0; //no eop
                             endcase
                           end //if(s_axis_rq_tready) begin
                         end // state WR_HEADER

          WR_DATA      : begin
                           if(s_axis_rq_tready) begin
                             interl_en_w = (curr_mwr_count == 0 | curr_mrd_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                             if(curr_mwr_len > 0) begin // Need more beats
                               nxt_state = WR_DATA;
                               curr_mwr_len_w = curr_mwr_len - 1; // counting multiple of 32 for rest data
                             end
                             else begin // data finish in this beat
                               if(curr_mwr_count == 0) begin // last write packet
                                 if(curr_mrd_count != 0) begin // read packet following
                                   nxt_state = RD;
                                   curr_mrd_count_w = curr_mrd_count - 1;
                                   curr_mrd_wrr_cnt_w = 0;
                                 end
                                 else begin // no read packet
                                   nxt_state = DONE;
                                   //rq_done_w = 1'b1;
                                 end
                               end
                               else if (interl_en && curr_mwr_wrr_cnt == 0) begin // last interl WR
                                 nxt_state = RD;
                                 curr_mrd_count_w = curr_mrd_count - 1;
                                 curr_mrd_wrr_cnt_w = mrd_wrr_cnt_i - 1;
                               end
                               else begin // not last write -> fetch next header
                                 nxt_state = WR_HEADER;
                                 curr_mwr_count_w = curr_mwr_count - 1;
                                 curr_mwr_wrr_cnt_w = curr_mwr_wrr_cnt - 1;
                                 curr_mwr_len_w = mwr_len_i >> 5; // counting multiple of 32 for rest data
                               end
                             end

                             //**** RQ Interface **** //
                             s_axis_rq_tvalid_w               = 1'b1;
                             s_axis_rq_tlast_w                = (curr_mwr_len > 0) ? 1'b0 : 1'b1;
                             // data can only ends @ DW3 (32 = 28 (header beat) + 4(data end beat))
                             s_axis_rq_tkeep_w                = (curr_mwr_len > 0) ? 32'hFFFFFFFF : 32'hF;

                             s_axis_rq_tdata_w[1023:0  ]       = {32{mwr_data_i}}; 

                             s_axis_rq_tuser_w.is_sop3_ptr = 2'b00; // no sop 
                             s_axis_rq_tuser_w.is_sop2_ptr = 2'b00; // no sop 
                             s_axis_rq_tuser_w.is_sop1_ptr = 2'b00; // no sop 
                             s_axis_rq_tuser_w.is_sop0_ptr = 2'b00; // no sop 
                             s_axis_rq_tuser_w.is_sop      = 4'b0000; // no sop 
                             s_axis_rq_tuser_w.is_eop3_ptr = 5'b0;
                             s_axis_rq_tuser_w.is_eop2_ptr = 5'b0;
                             s_axis_rq_tuser_w.is_eop1_ptr = 5'b0;
                             s_axis_rq_tuser_w.is_eop0_ptr = (curr_mwr_len > 0) ? 5'b0 : 5'b00011; 
                             s_axis_rq_tuser_w.is_eop      = (curr_mwr_len > 0) ? 4'b0 : 4'b0001;  
                             s_axis_rq_tuser_w.last_be     = 16'h0000; // no sop 
                             s_axis_rq_tuser_w.first_be    = 16'h0000; // no sop 
                           end //if(s_axis_rq_tready) begin
                         end // state WR_DATA

          RD           : begin
                           if(s_axis_rq_tready) begin
                             // if (avail_client_tag[client_tag_assigned_num_10bit_0] | ~AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                             if ( next_client_tag_available[0] ) begin
			       waiting_for_next_tag = 'b0;
                               interl_en_w = (curr_mwr_count == 0 | curr_mrd_count == 0) ? 0 : interl_en; //turn off interleave when there is no write packets left
                               if(curr_mrd_count == 0) begin 
                                 if(curr_mwr_count == 0) begin
                                   nxt_state = DONE;
                                   //rq_done_w = 1'b1;
                                 end
                                 else begin // only WR left
                                   nxt_state = WR_HEADER;
                                   curr_mwr_count_w = curr_mwr_count - 1;
                                   curr_mwr_wrr_cnt_w = 0;
                                   curr_mwr_len_w = mwr_len_i >> 5; // counting multiple of 32 for rest data
                                 end
                               end
                               else if(interl_en && curr_mrd_wrr_cnt == 0) begin // last interl RD
                                 nxt_state = WR_HEADER;
                                 curr_mwr_count_w = curr_mwr_count - 1;
                                 curr_mwr_wrr_cnt_w = mwr_wrr_cnt_i - 1;
                                 curr_mwr_len_w = mwr_len_i >> 5; // counting multiple of 32 for rest data
                               end
                               else begin 
                                 nxt_state = RD;
                                 curr_mrd_count_w = curr_mrd_count - 1;
                                 curr_mrd_wrr_cnt_w = curr_mrd_wrr_cnt - 1;
                               end
                               // Address counting counters:
                               r_tcnt_w            = r_tcnt + 1;

                               if (AXISTEN_IF_ENABLE_CLIENT_TAG) begin
                                 client_tag_assigned_0_wire           = 1'b1;
                                 client_tag_assigned_num_0_wire       = /*client_tag_assigned_num_10bit_0_p1;*/ incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_0, 1);
                                 client_tag_assigned_num_1_wire       = /*client_tag_assigned_num_10bit_1_p1;*/ incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_1, 1);
                                 client_tag_assigned_num_2_wire       = /*client_tag_assigned_num_10bit_2_p1;*/ incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_2, 1);
                                 client_tag_assigned_num_3_wire       = /*client_tag_assigned_num_10bit_3_p1;*/ incr_tag(cfg_10b_tag_requester_enable, client_tag_assigned_num_10bit_3, 1);
                                 s_axis_rq_tdata_w.h_0.tag            = client_tag_assigned_num_10bit_0[7:0];
                                 s_axis_rq_tdata_w.h_0.req_id_en      = client_tag_assigned_num_10bit_0[8];
                                 s_axis_rq_tdata_w.h_0.force_ecrc     = client_tag_assigned_num_10bit_0[9];
                               end
			       else begin
                                 s_axis_rq_tdata_w.h_0.tag            = 'd0; 
                                 s_axis_rq_tdata_w.h_0.req_id_en      = 'd0; 
                                 s_axis_rq_tdata_w.h_0.force_ecrc     = 'd0; 
			       end


                               //**** RQ Interface **** //
                               s_axis_rq_tvalid_w               = 1'b1;
                               s_axis_rq_tlast_w                = 1'b1;  // RD always ends within 1 beat 
                               s_axis_rq_tkeep_w                = 32'hF; // header -> 4 DW 

                               s_axis_rq_tdata_w[1023:128]       = 'd0;
                               s_axis_rq_tdata_w.h_0.req_type    = 4'b0000; // MemRd
                               s_axis_rq_tdata_w.h_0.dword_count = mrd_len_i;
                               s_axis_rq_tdata_w.h_0.addr_63_2   = {32'd0, rd_addr_31_2_0}; //TODO: address count
                               // clear tdata to zero
                               s_axis_rq_tdata_w.h_0.addr_type       = 2'b0;
                               s_axis_rq_tdata_w.h_0[95:79]          = 'd0; // req_id, poisoned_req
                               s_axis_rq_tdata_w.h_0[119:104]        = 'd0; // cmpl_id
                               s_axis_rq_tdata_w.h_0[126:121]        = 'd0; // attr, tc 

                               s_axis_rq_tuser_w.is_sop3_ptr = 2'b00; 
                               s_axis_rq_tuser_w.is_sop2_ptr = 2'b00; 
                               s_axis_rq_tuser_w.is_sop1_ptr = 2'b00; 
                               s_axis_rq_tuser_w.is_sop0_ptr = 2'b00; 
                               s_axis_rq_tuser_w.is_sop      = 4'b0000;
                               s_axis_rq_tuser_w.is_eop3_ptr = 5'b0;
                               s_axis_rq_tuser_w.is_eop2_ptr = 5'b0;
                               s_axis_rq_tuser_w.is_eop1_ptr = 5'b0;
                               s_axis_rq_tuser_w.is_eop0_ptr = 5'b00011;
                               s_axis_rq_tuser_w.is_eop      = 4'b0001;
                               s_axis_rq_tuser_w.last_be     = mrd_len_i[0] ? 16'h0 : 16'h000F; 
                               s_axis_rq_tuser_w.first_be    = 16'h000F;
                             end // no available tag
			     else begin
                               client_tag_assigned_0_wire    = 1'b0;
                               client_tag_assigned_1_wire    = 1'b0;
                               client_tag_assigned_2_wire    = 1'b0;
                               client_tag_assigned_3_wire    = 1'b0;
			       waiting_for_next_tag          = 'b1;
                               s_axis_rq_tvalid_w            = 1'b0; // Pull down the valid if tag is not available
			     end
                           end //if(s_axis_rq_tready) begin
                         end // state RD

          DONE         : begin
                           if(s_axis_rq_tready) begin
                             rq_done_w = 1'b1;
                             nxt_state = IDLE;
                             s_axis_rq_tvalid_w = 1'b0;
                           end //if(s_axis_rq_tready) begin
                         end // state DONE
        endcase // case(state) - State Machine
     end //always_comb
   end //DW-aligned
   endgenerate

// Generate parity for data
// TODO: gtz Make it parameterize
genvar var_i;
generate
   for (var_i = 0; var_i < 64; var_i = var_i + 1) begin: rq_parity_generation
      assign s_axis_rq_parity[var_i] =  ~(^s_axis_rq_tdata_w[8*(var_i+1)-1:8*var_i]);
   end
endgenerate

   always_comb begin
      s_axis_rq_tuser_w_parity         = s_axis_rq_tuser_w;
      s_axis_rq_tuser_w_parity.parity  = AXISTEN_IF_REQ_PARITY_CHECK? s_axis_rq_parity: 64'd0;
   end


//-------------------------------------------------------------
// I/O
//-------------------------------------------------------------
   assign s_axis_rq_tdata  = s_axis_rq_tdata_reg;
   assign s_axis_rq_tuser  = s_axis_rq_tuser_reg;


//-------------------------------------------------------------
// Register
//-------------------------------------------------------------
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tdata_reg, s_axis_rq_tdata_w , 1024'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tkeep    , s_axis_rq_tkeep_w , 32'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tlast    , s_axis_rq_tlast_w , 1'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tvalid   , s_axis_rq_tvalid_w, 1'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), s_axis_rq_tuser_reg, s_axis_rq_tuser_w_parity, 373'd0)

   `BMDREG(user_clk, (reset_n & ~init_rst_i), rq_done            , rq_done_w        , 1'd0)

   `BMDREG(user_clk, (reset_n & ~init_rst_i), state              , nxt_state         , IDLE)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), curr_mwr_count     , curr_mwr_count_w  , 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), curr_mrd_count     , curr_mrd_count_w  , 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), curr_mwr_wrr_cnt   , curr_mwr_wrr_cnt_w, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), curr_mrd_wrr_cnt   , curr_mrd_wrr_cnt_w, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), curr_mwr_len       , curr_mwr_len_w    , 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), wr_end_case        , wr_end_case_w     , 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), interl_en          , interl_en_w       , 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), w_tcnt             , w_tcnt_w          , 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), r_tcnt             , r_tcnt_w          , 'd0)

   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_0, client_tag_assigned_0_wire, 1'b0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_1, client_tag_assigned_1_wire, 1'b0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_2, client_tag_assigned_2_wire, 1'b0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_3, client_tag_assigned_3_wire, 1'b0)
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_num_0, client_tag_assigned_num_0_wire, (cfg_10b_tag_requester_enable ? 'd256 : 'd0))
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_num_1, client_tag_assigned_num_1_wire, (cfg_10b_tag_requester_enable ? 'd257 : 'd1))
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_num_2, client_tag_assigned_num_2_wire, (cfg_10b_tag_requester_enable ? 'd258 : 'd2))
   //`BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_num_3, client_tag_assigned_num_3_wire, (cfg_10b_tag_requester_enable ? 'd259 : 'd3))
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_num_0_d1, client_tag_assigned_num_0, 'd0)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_num_1_d1, client_tag_assigned_num_1, 'd1)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_num_2_d1, client_tag_assigned_num_2, 'd2)
   `BMDREG(user_clk, (reset_n & ~init_rst_i), client_tag_assigned_num_3_d1, client_tag_assigned_num_3, 'd3)

    always @ (posedge user_clk)
    begin
      if(!reset_n)
      begin
        client_tag_assigned_num_0 <= 'd0;
        client_tag_assigned_num_1 <= 'd1;
        client_tag_assigned_num_2 <= 'd2;
        client_tag_assigned_num_3 <= 'd3;
      end
      else if(init_rst_i)
      begin
        client_tag_assigned_num_0 <= cfg_10b_tag_requester_enable ? 'd256 : 'd0;
        client_tag_assigned_num_1 <= cfg_10b_tag_requester_enable ? 'd257 : 'd1;
        client_tag_assigned_num_2 <= cfg_10b_tag_requester_enable ? 'd258 : 'd2;
        client_tag_assigned_num_3 <= cfg_10b_tag_requester_enable ? 'd259 : 'd3;
      end
      else
      begin
        client_tag_assigned_num_0 <= client_tag_assigned_num_0_wire; 
        client_tag_assigned_num_1 <= client_tag_assigned_num_1_wire; 
        client_tag_assigned_num_2 <= client_tag_assigned_num_2_wire; 
        client_tag_assigned_num_3 <= client_tag_assigned_num_3_wire; 
      end
    end
//-------------------------------------------------------------
// function definition
//-------------------------------------------------------------
function [2:0] wr_len_interval;
input [10:0] wr_len; 
  begin
    if(wr_len > 28) wr_len_interval = 0; 
    else if(wr_len > 20) wr_len_interval = 1;
    else if(wr_len > 12) wr_len_interval = 2;
    else if(wr_len > 4)  wr_len_interval = 3;
    else wr_len_interval = 4;
  end
endfunction

function [3:0] log_case;
input [10:0] wr_len; 
  begin
    case(1'b1) 
      wr_len[ 0]: log_case =  0;
      wr_len[ 1]: log_case =  1;
      wr_len[ 2]: log_case =  2;
      wr_len[ 3]: log_case =  3;
      wr_len[ 4]: log_case =  4;
      wr_len[ 5]: log_case =  5;
      wr_len[ 6]: log_case =  6;
      wr_len[ 7]: log_case =  7;
      wr_len[ 8]: log_case =  8;
      wr_len[ 9]: log_case =  9;
      wr_len[10]: log_case = 10;
      default:    log_case =  0;
    endcase
  end
endfunction

// Function to check parity of incoming data
function [9:0] incr_tag;
   input       cfg_10b_tag_requester_enable;
   input [9:0] curr_value;
   input [3:0] incr_val;

   reg [9:0] local_sum;

   local_sum[9:0] = curr_value[9:0] + incr_val[3:0];
   if (cfg_10b_tag_requester_enable ) begin
      incr_tag[7:0] = local_sum[7:0]; 
      incr_tag[9:8] = local_sum[9:8] == 2'b00 ? 2'b01 : local_sum[9:8];
   end else begin // Data Check
      incr_tag[7:0] = local_sum[7:0]; 
      incr_tag[9:8] = 2'b00;
   end
endfunction



endmodule // BMD_AXIST_RQ_RW_1024

