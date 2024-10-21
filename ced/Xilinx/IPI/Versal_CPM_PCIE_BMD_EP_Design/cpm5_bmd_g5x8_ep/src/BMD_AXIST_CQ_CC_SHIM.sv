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
// Project    : UltraScale+ FPGA PCI Express v4.0 Integrated Block
// File       : BMD_AXIST_CQ_CC_SHIM.sv
// Version    : 1.3 
//-----------------------------------------------------------------------------

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

