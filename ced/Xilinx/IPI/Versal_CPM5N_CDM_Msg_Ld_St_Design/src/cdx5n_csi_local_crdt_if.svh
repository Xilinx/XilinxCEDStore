// /////////////////////////////////////////////////////////////////
// (c) Copyright 2019 - 2020 Xilinx, Inc. All rights reserved.	 
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
// ////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
// 
//-----------------------------------------------------------------------------
//
// Filename        : 
// Version         : 
// Description     : 
// Verilog-Standard: 
//-----------------------------------------------------------------------------
//-- Structure:
//--               -- module
//                     -- module
//-----------------------------------------------------------------------------
// Naming Conventions:
//      active low signals:                     "*_n"
//      clock signals:                          "clk", "clk_div#", "clk_#x" 
//      reset signals:                          "rst", "rst_n" 
//      input signals:                          "i_*"
//      output signals:                         "o_*"
//      parameters:                             "C_*" 
//      user defined types:                     "*_TYPE" 
//      state machine next state:               "*_ns" 
//      state machine current state:            "*_cs" 
//      combinatorial signals:                  "*_com" 
//      pipelined or register delay signals:    "*_d#" 
//      counter signals:                        "*cnt*"
//      clock enable signals:                   "*_ce" 
//      internal version of output port         "*_i"
//      device pins:                            "*_pin" 
//      component instantiations:               "<MODULE>I_<#|FUNC>
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////


`ifndef CDX5N_CSI_LOCAL_CRDT_IF
`define CDX5N_CSI_LOCAL_CRDT_IF

`include "cdx5n_csi_defines.svh"


interface cdx5n_csi_local_crdt_if ();

  logic [1:0]  local_crdt_snk_id;
  logic [1:0]  local_crdt_src_furc_id;
  csi_flow_t   local_crdt_flow_type;
  logic [6:0]  local_crdt_buf_id;
  logic [15:0] local_crdt;
  logic        local_crdt_vld;
  logic        local_crdt_rdy;
  


  modport m(
    output local_crdt_snk_id,
    output local_crdt_src_furc_id,
    output local_crdt_flow_type,
    output local_crdt_buf_id,
    output local_crdt,
    output local_crdt_vld,
    input  local_crdt_rdy
  );

  modport s(
    input  local_crdt_snk_id,
    input local_crdt_src_furc_id,
    input  local_crdt_flow_type,
    input  local_crdt_buf_id,
    input  local_crdt,
    input  local_crdt_vld,
    output local_crdt_rdy
  );

  modport mon (
    input  local_crdt_snk_id,
    input local_crdt_src_furc_id,
    input  local_crdt_flow_type,
    input  local_crdt_buf_id,
    input  local_crdt,
    input  local_crdt_vld,
    input  local_crdt_rdy
  );

endinterface






`endif
