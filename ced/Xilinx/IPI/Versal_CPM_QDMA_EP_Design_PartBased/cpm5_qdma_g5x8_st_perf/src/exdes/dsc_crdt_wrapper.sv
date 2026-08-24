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
// Project    : The PCI Express DMA 
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

