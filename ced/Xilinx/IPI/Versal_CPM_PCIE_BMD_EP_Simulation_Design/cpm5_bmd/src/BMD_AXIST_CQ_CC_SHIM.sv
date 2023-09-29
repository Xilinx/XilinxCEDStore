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

//`include "pcie_app_uscale_bmd.vh"
`include "pcie_app_uscale_bmd_1024.vh"
`timescale 1ps / 1ps
`STRUCT_AXI_CQ_IF_512
`STRUCT_AXI_CC_IF_512
`STRUCT_AXI_CQ_IF_1024
`STRUCT_AXI_CC_IF_1024

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_CQ_CC_SHIM (
   //CQ: 1024b from hard block, 512 to user
   input s_axis_cq_tuser_1024 m_axis_cq_tuser_1024,
   input [31:0]               m_axis_cq_tkeep_1024,
   input [1023:0]             m_axis_cq_tdata_1024,

   output s_axis_cq_tuser_512 m_axis_cq_tuser_512,
   output [15:0]              m_axis_cq_tkeep_512,
   output [511:0]             m_axis_cq_tdata_512,

   //CC: 512b from user, 1024b to hard block
   input [511:0]             s_axis_cc_tdata_512,
   input [15:0]              s_axis_cc_tkeep_512,
   input s_axis_cc_tuser_512 s_axis_cc_tuser_512,

   output [1023:0]             s_axis_cc_tdata_1024,
   output [31:0]               s_axis_cc_tkeep_1024,
   output s_axis_cc_tuser_1024 s_axis_cc_tuser_1024
);

   //CQ: 1024b from hard block, 512 to user
   assign m_axis_cq_tkeep_512 = m_axis_cq_tkeep_1024[15:0];
   assign m_axis_cq_tdata_512 = m_axis_cq_tdata_1024[511:0];   
   assign m_axis_cq_tuser_512.parity     [63:0] = m_axis_cq_tuser_1024.parity     [63:0];
   assign m_axis_cq_tuser_512.tph_st_tag [15:0] = m_axis_cq_tuser_1024.tph_st_tag [15:0];
   assign m_axis_cq_tuser_512.tph_type   [3:0]  = m_axis_cq_tuser_1024.tph_type   [3:0] ;
   assign m_axis_cq_tuser_512.tph_present[1:0]  = m_axis_cq_tuser_1024.tph_present[1:0] ;
   assign m_axis_cq_tuser_512.discontinue       = m_axis_cq_tuser_1024.discontinue      ;
   assign m_axis_cq_tuser_512.is_eop1_ptr[3:0]  = m_axis_cq_tuser_1024.is_eop1_ptr[3:0] ;
   assign m_axis_cq_tuser_512.is_eop0_ptr[3:0]  = m_axis_cq_tuser_1024.is_eop0_ptr[3:0] ;
   assign m_axis_cq_tuser_512.is_eop     [1:0]  = m_axis_cq_tuser_1024.is_eop     [1:0] ;
   assign m_axis_cq_tuser_512.is_sop1_ptr[1:0]  = m_axis_cq_tuser_1024.is_sop1_ptr[1:0] ;
   assign m_axis_cq_tuser_512.is_sop0_ptr[1:0]  = m_axis_cq_tuser_1024.is_sop0_ptr[1:0] ;
   assign m_axis_cq_tuser_512.is_sop     [1:0]  = m_axis_cq_tuser_1024.is_sop     [1:0] ;
   assign m_axis_cq_tuser_512.byte_en    [63:0] = m_axis_cq_tuser_1024.byte_en    [63:0];
   assign m_axis_cq_tuser_512.last_be    [7:0]  = m_axis_cq_tuser_1024.last_be    [7:0] ;
   assign m_axis_cq_tuser_512.first_be   [7:0]  = m_axis_cq_tuser_1024.first_be   [7:0] ;

   //CC: 512b from user, 1024b to hard block
   assign s_axis_cc_tkeep_1024 = {16'd0,  s_axis_cc_tkeep_512};
   assign s_axis_cc_tdata_1024 = {512'd0, s_axis_cc_tdata_512};   
   assign s_axis_cc_tuser_1024.parity     [127:0] = {64'd0, s_axis_cc_tuser_512.parity};
   assign s_axis_cc_tuser_1024.discontinue        = s_axis_cc_tuser_512.discontinue;
   assign s_axis_cc_tuser_1024.is_eop3_ptr[4:0]   = 5'd0;
   assign s_axis_cc_tuser_1024.is_eop2_ptr[4:0]   = 5'd0;
   assign s_axis_cc_tuser_1024.is_eop1_ptr[4:0]   = s_axis_cc_tuser_512.is_eop1_ptr;
   assign s_axis_cc_tuser_1024.is_eop0_ptr[4:0]   = s_axis_cc_tuser_512.is_eop0_ptr;
   assign s_axis_cc_tuser_1024.is_eop     [3:0]   = {2'd0, s_axis_cc_tuser_512.is_eop};
   assign s_axis_cc_tuser_1024.is_sop3_ptr[1:0]   = 2'd0;
   assign s_axis_cc_tuser_1024.is_sop2_ptr[1:0]   = 2'd0;
   assign s_axis_cc_tuser_1024.is_sop1_ptr[1:0]   = s_axis_cc_tuser_512.is_sop1_ptr;
   assign s_axis_cc_tuser_1024.is_sop0_ptr[1:0]   = s_axis_cc_tuser_512.is_sop0_ptr;
   assign s_axis_cc_tuser_1024.is_sop     [3:0]   = {2'd0, s_axis_cc_tuser_512.is_sop};

endmodule // BMD_CQ_CC_SHIM

