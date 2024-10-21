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
// Project    : The Xilinx PCI Express DMA 
// File       : dsc_crdt.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

/* This is a wrapper for all Descriptor Credit Modules
*/

module dsc_crdt_wrapper # (
  parameter QID_WIDTH   = 11,                           // Must be 11. Queue ID bit width
  parameter TM_DSC_BITS = 16,                           // Traffic Manager descriptor credit bit width
  parameter TCQ         = 1
) (
  // Global
  input  logic                     user_clk,
  input  logic                     user_reset_n,
  
  // Control Signals
  input  [31:0]                    knob,                // [0] = C2H Descriptor Credit Fence bit.
                                                        // [1] = 1 enables this Descriptor Credit module (QDMA in Simple Bypass mode). Must only toggle bit [1] before any Queue is started
                                                        // [31:27] = H2C Credit amount to batch.
  
  // To queue_cnts for C2H
  output logic                     c2h_qid_rdy,
  input  logic                     c2h_qid_vld,
  input  logic [QID_WIDTH-1:0]     c2h_qid,
  input  logic [TM_DSC_BITS-1:0]   c2h_qid_desc_avail,
  output logic                     c2h_desc_cnt_dec,
  output logic [QID_WIDTH-1:0]     c2h_desc_cnt_dec_qid,
  output logic                     c2h_requeue_vld,
  output logic [QID_WIDTH-1:0]     c2h_requeue_qid,
  input  logic                     c2h_requeue_rdy,
  
  // To queue_cnts for H2C
  output logic                     h2c_qid_rdy,
  input  logic                     h2c_qid_vld,
  input  logic [QID_WIDTH-1:0]     h2c_qid,
  input  logic [TM_DSC_BITS-1:0]   h2c_qid_desc_avail,
  output logic                     h2c_desc_cnt_dec,
  output logic [QID_WIDTH-1:0]     h2c_desc_cnt_dec_qid,
  output logic                     h2c_requeue_vld,
  output logic [QID_WIDTH-1:0]     h2c_requeue_qid,
  input  logic                     h2c_requeue_rdy,
  
  // To Data Generator for C2H
  output logic [TM_DSC_BITS-1:0]   c2h_dg_qid_desc_avail,
  output logic [QID_WIDTH-1:0]     c2h_dg_qid,
  output logic                     c2h_dg_qid_vld,
  input  logic                     c2h_dg_qid_rdy,
  input  logic [QID_WIDTH-1:0]     c2h_dg_desc_cnt_dec_qid,
  input  logic                     c2h_dg_desc_cnt_dec,
  input  logic [QID_WIDTH-1:0]     c2h_dg_requeue_qid,
  input  logic                     c2h_dg_requeue_vld,
  output logic                     c2h_dg_requeue_rdy,
  
  // From ST_C2H Logic (if not enabled, then the value is save to ignore)
  input  logic [4:0]               c2h_dsc_req_val,
  input  logic [QID_WIDTH-1:0]     c2h_dsc_req_qid,
  input  logic                     c2h_dsc_req_vld,
  
  // QDMA Descriptor Credit Bus
  output logic [TM_DSC_BITS-1:0]   dsc_crdt_in_crdt,
  output logic                     dsc_crdt_in_dir,
  output logic                     dsc_crdt_in_fence,
  output logic [QID_WIDTH-1:0]     dsc_crdt_in_qid,
  input  logic                     dsc_crdt_in_rdy,
  output logic                     dsc_crdt_in_valid
);

// Descriptor Credit In Signals
logic [TM_DSC_BITS-1:0]            c2h_dsc_crdt_in_crdt , h2c_dsc_crdt_in_crdt;
logic                              c2h_dsc_crdt_in_dir  , h2c_dsc_crdt_in_dir;
logic                              c2h_dsc_crdt_in_fence, h2c_dsc_crdt_in_fence;
logic [QID_WIDTH-1:0]              c2h_dsc_crdt_in_qid  , h2c_dsc_crdt_in_qid;
logic                              c2h_dsc_crdt_in_rdy  , h2c_dsc_crdt_in_rdy;
logic                              c2h_dsc_crdt_in_valid, h2c_dsc_crdt_in_valid;

logic [TM_DSC_BITS-1:0]            h2c_dg_qid_desc_avail;
logic [QID_WIDTH-1:0]              h2c_dg_qid;
logic                              h2c_dg_qid_vld;
logic                              h2c_dg_qid_rdy;
logic [QID_WIDTH-1:0]              h2c_dg_desc_cnt_dec_qid;
logic                              h2c_dg_desc_cnt_dec;
logic [QID_WIDTH-1:0]              h2c_dg_requeue_qid;
logic                              h2c_dg_requeue_vld;
logic                              h2c_dg_requeue_rdy;
logic [4:0]                        h2c_dsc_req_val;
logic [QID_WIDTH-1:0]              h2c_dsc_req_qid;
logic                              h2c_dsc_req_vld;

ST_h2c_crdt # (
  .QID_WIDTH               ( QID_WIDTH                 ),
  .TM_DSC_BITS             ( TM_DSC_BITS               ),
  .TCQ                     ( TCQ                       )
) ST_h2c_crdt_i (
  .user_clk                ( user_clk                  ),
  .user_reset_n            ( user_reset_n              ),
  
  .knob                    ( {knob[31:27], 27'b0}      ), // bit [4:0] Amount to batch.
  
  .credit_in               ( h2c_dg_qid_desc_avail     ),
  .qid                     ( h2c_dg_qid                ),
  .credit_rdy              ( h2c_dg_qid_rdy            ),
  .credit_vld              ( h2c_dg_qid_vld            ),
  .dec_qid                 ( h2c_dg_desc_cnt_dec_qid   ),
  .dec_credit              ( h2c_dg_desc_cnt_dec       ),
  .requeue_qid             ( h2c_dg_requeue_qid        ),
  .requeue_credit          ( h2c_dg_requeue_vld        ),
  .requeue_rdy             ( h2c_dg_requeue_rdy        ),
  
  .dsc_req_val             ( h2c_dsc_req_val           ),
  .dsc_req_qid             ( h2c_dsc_req_qid           ),
  .dsc_req_vld             ( h2c_dsc_req_vld           )
);

dsc_crdt #(
  .DIR                     ( 1                         ), // 0=H2C; 1=C2H
  .QID_WIDTH               ( QID_WIDTH                 ),
  .TM_DSC_BITS             ( TM_DSC_BITS               ),
  .TCQ                     ( TCQ                       )
) c2h_dsc_crdt_i (
  .user_clk                ( user_clk                  ),
  .user_reset_n            ( user_reset_n              ),
  
  .knob                    ( {31'b0, knob[1], knob[0]} ), // bit [0] fence. bit [1] enables descriptor credit
  
  .qc_credit_in            ( c2h_qid_desc_avail        ),
  .qc_qid                  ( c2h_qid                   ),
  .qc_credit_rdy           ( c2h_qid_rdy               ),
  .qc_credit_vld           ( c2h_qid_vld               ),
  .qc_dec_qid              ( c2h_desc_cnt_dec_qid      ),
  .qc_dec_credit           ( c2h_desc_cnt_dec          ),
  .qc_requeue_qid          ( c2h_requeue_qid           ),
  .qc_requeue_credit       ( c2h_requeue_vld           ),
  .qc_requeue_rdy          ( c2h_requeue_rdy           ),
  
  .dg_credit_in            ( c2h_dg_qid_desc_avail     ),
  .dg_qid                  ( c2h_dg_qid                ),
  .dg_credit_rdy           ( c2h_dg_qid_rdy            ),
  .dg_credit_vld           ( c2h_dg_qid_vld            ),
  .dg_dec_qid              ( c2h_dg_desc_cnt_dec_qid   ),
  .dg_dec_credit           ( c2h_dg_desc_cnt_dec       ),
  .dg_requeue_qid          ( c2h_dg_requeue_qid        ),
  .dg_requeue_credit       ( c2h_dg_requeue_vld        ),
  .dg_requeue_rdy          ( c2h_dg_requeue_rdy        ),
  
  .dsc_req_val             ( c2h_dsc_req_val           ),
  .dsc_req_qid             ( c2h_dsc_req_qid           ),
  .dsc_req_vld             ( c2h_dsc_req_vld           ),
  
  .dsc_crdt_in_crdt        ( c2h_dsc_crdt_in_crdt      ),
  .dsc_crdt_in_dir         ( c2h_dsc_crdt_in_dir       ),
  .dsc_crdt_in_fence       ( c2h_dsc_crdt_in_fence     ),
  .dsc_crdt_in_qid         ( c2h_dsc_crdt_in_qid       ),
  .dsc_crdt_in_rdy         ( c2h_dsc_crdt_in_rdy       ),
  .dsc_crdt_in_valid       ( c2h_dsc_crdt_in_valid     )
);

dsc_crdt #(
  .DIR                     ( 1                         ), // 0=H2C; 1=C2H
  .QID_WIDTH               ( QID_WIDTH                 ),
  .TM_DSC_BITS             ( TM_DSC_BITS               ),
  .TCQ                     ( TCQ                       )
) h2c_dsc_crdt_i (
  .user_clk                ( user_clk                  ),
  .user_reset_n            ( user_reset_n              ),
  
  .knob                    ( {31'b0, knob[1], 1'b0}    ), // bit [0] fence. bit [1] enables descriptor credit
  
  .qc_credit_in            ( h2c_qid_desc_avail        ),
  .qc_qid                  ( h2c_qid                   ),
  .qc_credit_rdy           ( h2c_qid_rdy               ),
  .qc_credit_vld           ( h2c_qid_vld               ),
  .qc_dec_qid              ( h2c_desc_cnt_dec_qid      ),
  .qc_dec_credit           ( h2c_desc_cnt_dec          ),
  .qc_requeue_qid          ( h2c_requeue_qid           ),
  .qc_requeue_credit       ( h2c_requeue_vld           ),
  .qc_requeue_rdy          ( h2c_requeue_rdy           ),
  
  .dg_credit_in            ( h2c_dg_qid_desc_avail     ),
  .dg_qid                  ( h2c_dg_qid                ),
  .dg_credit_rdy           ( h2c_dg_qid_rdy            ),
  .dg_credit_vld           ( h2c_dg_qid_vld            ),
  .dg_dec_qid              ( h2c_dg_desc_cnt_dec_qid   ),
  .dg_dec_credit           ( h2c_dg_desc_cnt_dec       ),
  .dg_requeue_qid          ( h2c_dg_requeue_qid        ),
  .dg_requeue_credit       ( h2c_dg_requeue_vld        ),
  .dg_requeue_rdy          ( h2c_dg_requeue_rdy        ),
  
  .dsc_req_val             ( h2c_dsc_req_val           ),
  .dsc_req_qid             ( h2c_dsc_req_qid           ),
  .dsc_req_vld             ( h2c_dsc_req_vld           ),
  
  .dsc_crdt_in_crdt        ( h2c_dsc_crdt_in_crdt      ),
  .dsc_crdt_in_dir         ( h2c_dsc_crdt_in_dir       ),
  .dsc_crdt_in_fence       ( h2c_dsc_crdt_in_fence     ),
  .dsc_crdt_in_qid         ( h2c_dsc_crdt_in_qid       ),
  .dsc_crdt_in_rdy         ( h2c_dsc_crdt_in_rdy       ),
  .dsc_crdt_in_valid       ( h2c_dsc_crdt_in_valid     )
);

dsc_crdt_mux # (
  .QID_WIDTH               ( QID_WIDTH                 ),
  .TM_DSC_BITS             ( TM_DSC_BITS               ),
  .TCQ                     ( TCQ                       )
) dsc_crdt_mux_i (
  .user_clk                ( user_clk                  ),
  .user_reset_n            ( user_reset_n              ),
  
  .c2h_dsc_crdt_in_crdt    ( c2h_dsc_crdt_in_crdt      ),
  .c2h_dsc_crdt_in_dir     ( c2h_dsc_crdt_in_dir       ),
  .c2h_dsc_crdt_in_fence   ( c2h_dsc_crdt_in_fence     ),
  .c2h_dsc_crdt_in_qid     ( c2h_dsc_crdt_in_qid       ),
  .c2h_dsc_crdt_in_rdy     ( c2h_dsc_crdt_in_rdy       ),
  .c2h_dsc_crdt_in_valid   ( c2h_dsc_crdt_in_valid     ),
  
  .h2c_dsc_crdt_in_crdt    ( h2c_dsc_crdt_in_crdt      ),
  .h2c_dsc_crdt_in_dir     ( h2c_dsc_crdt_in_dir       ),
  .h2c_dsc_crdt_in_fence   ( h2c_dsc_crdt_in_fence     ),
  .h2c_dsc_crdt_in_qid     ( h2c_dsc_crdt_in_qid       ),
  .h2c_dsc_crdt_in_rdy     ( h2c_dsc_crdt_in_rdy       ),
  .h2c_dsc_crdt_in_valid   ( h2c_dsc_crdt_in_valid     ),
  
  .dsc_crdt_in_crdt        ( dsc_crdt_in_crdt          ),
  .dsc_crdt_in_dir         ( dsc_crdt_in_dir           ),
  .dsc_crdt_in_fence       ( dsc_crdt_in_fence         ),
  .dsc_crdt_in_qid         ( dsc_crdt_in_qid           ),
  .dsc_crdt_in_rdy         ( dsc_crdt_in_rdy           ),
  .dsc_crdt_in_valid       ( dsc_crdt_in_valid         )
);

endmodule

