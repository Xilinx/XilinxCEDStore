// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
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

`ifndef MAILBOX_TOP_SV
`define MAILBOX_TOP_SV
`include "mailbox_defines.svh"

`timescale 1ns/1ps
module qdma_v2_0_1_mailbox_top
# (
 parameter N_PF                  = 4,   // Number of PFs
 parameter N_FN                  = 256, // Total number of functions
 parameter CSR_ADDR_W            = 12,  // Actual CSR address width
 parameter MAX_MSG_SIZE          = 64,  // Maximum message size (Bytes)
 parameter AXIL_ADDR_W           = 32,
 parameter AXIL_DATA_W           = 32,
 parameter AXIL_USER_W           = 29, 
 parameter NUM_VFS_PF0           = 8,
 parameter NUM_VFS_PF1           = 8,
 parameter NUM_VFS_PF2           = 8,
 parameter NUM_VFS_PF3           = 8,
 parameter FIRSTVF_OFFSET_PF0    = 4,
 parameter FIRSTVF_OFFSET_PF1    = 11,
 parameter FIRSTVF_OFFSET_PF2    = 18,
 parameter FIRSTVF_OFFSET_PF3    = 25, 
 parameter RTL_REVISION          = 32'h0,
 parameter PATCH_REVIVION        = 32'h0, 
 parameter MDMA_CMN_EXT_START_A  = 32'h2400,
 parameter USER_INT_VECT_W       = 5,  //Width of user interrupt vector
 parameter MDMA_VF_EXT_START_A   = 0
)
(
 input                         clk,
 input                         rst,
 mailbox_axi4lite_if.s         axi4l_s,
 //Mailbox user interrupt
 input                         usr_irq_ack,
 input                         usr_irq_fail,
 output                        usr_irq_vld,
 output [USER_INT_VECT_W-1:0]  usr_irq_vec,
 output [$clog2(N_FN)-1:0]     usr_irq_fnc,

 //Mailbox <-> FLR interface
 output mailbox_mb2flr_data_t  mb2flr_data,
 output                        mb2flr_push,
 input [N_FN-1:0]              flr_status,

 input                         flr2mb_req,
 output                        flr2mb_ack,
 input [$clog2(N_FN)-1:0]      flr2mb_fn,
 
 output [11:0]                 csr_addr,
 output [19:0]                 debug_fsm

);

localparam PF_ADDR_OFFSET = MDMA_CMN_EXT_START_A;
localparam VF_ADDR_OFFSET = MDMA_VF_EXT_START_A;

localparam MSG_MEM_W         = 32;
localparam MSG_MEM_PAR_W     = MSG_MEM_W / 8; 
localparam MSG_MEM_DEPTH     = 2*N_FN*(MAX_MSG_SIZE*8/MSG_MEM_W);
localparam MSG_MEM_ADR_W     = $clog2(MSG_MEM_DEPTH);
localparam MSG_MEM_FFOUT     = 1;
localparam MSG_MEM_R_LATENCY = MSG_MEM_FFOUT +1;

localparam INTV_MEM_W         = USER_INT_VECT_W;
localparam INTV_MEM_PAR_W     = 1; 
localparam INTV_MEM_DEPTH     = N_FN;
localparam INTV_MEM_ADR_W     = $clog2(INTV_MEM_DEPTH);
localparam INTV_MEM_FFOUT     = 1;
localparam INTV_MEM_R_LATENCY = INTV_MEM_FFOUT +1;


mailbox_xpm_sdpram_if # (
    .MEM_W         (MSG_MEM_W), 
    .ADR_W         (MSG_MEM_ADR_W), 
    .WBE_W         (1) 
) msg_mem ();

mailbox_xpm_sdpram_if # (
    .MEM_W         (INTV_MEM_W), 
    .ADR_W         (INTV_MEM_ADR_W), 
    .WBE_W         (1) 
) intv_mem ();

logic [$clog2(N_FN)-1:0] pfq_push_event; 
logic [$clog2(N_FN)-1:0] pfq_cur_event [N_PF-1:0]; 
logic          pfq_push      [N_PF-1:0]; 
logic          pfq_pop       [N_PF-1:0]; 
logic          pfq_rst       [N_PF-1:0]; 
logic          pfq_cur_evld  [N_PF-1:0]; 
logic          pfq_overflow  [N_PF-1:0]; 
logic          pfq_underflow [N_PF-1:0];

wire                        fn_irq_en [N_FN-1:0];
wire                        inte_vld; 
wire [$clog2(N_FN)-1:0]     inte_fnc;
wire                        irq_vect_rd;
wire [$clog2(N_FN)-1:0]     irq_vect_rd_addr;
wire                        irq_vect_rd_vld;
wire [USER_INT_VECT_W-1:0]  irq_vect_rd_data;
/*******************************************************************************/
// mailbox FSM
/*******************************************************************************/
qdma_v2_0_1_mailbox_fsm 
# (
 .N_PF            (N_PF          ), 
 .N_FN            (N_FN          ), 
 .MAX_MSG_SIZE    (MAX_MSG_SIZE  ), 
 .AXIL_ADDR_W     (AXIL_ADDR_W   ), 
 .AXIL_DATA_W     (AXIL_DATA_W   ), 
 .AXIL_USER_W     (AXIL_USER_W   ),
 .CSR_ADDR_W      (CSR_ADDR_W    ), 
 .MSG_MEM_W       (MSG_MEM_W     ), 
 .PF_ADDR_OFFSET  (PF_ADDR_OFFSET),
 .VF_ADDR_OFFSET  (VF_ADDR_OFFSET), 
 .RTL_REVISION    (RTL_REVISION  ),
 .PATCH_REVIVION  (PATCH_REVIVION), 
 .USER_INT_VECT_W (USER_INT_VECT_W),
 .INTV_MEM_W      (INTV_MEM_W    ) 
) u_mailbox_fsm
(
 .clk              (clk           ),
 .rst              (rst           ),
 .axi4l_s          (axi4l_s       ),
 .msg_mem          (msg_mem       ),
 .intv_mem         (intv_mem      ),
 .pfq_push         (pfq_push      ),
 .pfq_push_event   (pfq_push_event),
 .pfq_pop          (pfq_pop       ),
 .pfq_rst          (pfq_rst       ),
 .pfq_cur_event    (pfq_cur_event ),
 .pfq_cur_evld     (pfq_cur_evld  ),
 .pfq_overflow     (pfq_overflow  ),
 .pfq_underflow    (pfq_underflow ),
 .mb2flr_push      (mb2flr_push),
 .mb2flr_data      (mb2flr_data),
 .flr_status       (flr_status), 
 .flr2mb_req       (flr2mb_req),
 .flr2mb_fn        (flr2mb_fn ),
 .flr2mb_ack       (flr2mb_ack),
 .fn_irq_en        (fn_irq_en       ), 
 .inte_vld         (inte_vld        ), 
 .inte_fnc         (inte_fnc        ), 
 .inte_ack         (inte_ack        ), 
 .irq_vect_rd      (irq_vect_rd     ), 
 .irq_vect_rd_addr (irq_vect_rd_addr), 
 .irq_vect_rd_vld  (irq_vect_rd_vld ), 
 .irq_vect_rd_data (irq_vect_rd_data),
 .dbg_out_debug_fsm(debug_fsm),
 .dbg_out_csr_addr (csr_addr)

);

/*******************************************************************************/
// msg memory
// 1. lower half: vf outgoing message memory
// 2. upper half: vf incoming message memory
/*******************************************************************************/
qdma_v2_0_1_mailbox_msg_mem 
  #(
    .MEM_W         (MSG_MEM_W), 
    .ADR_W         (MSG_MEM_ADR_W), 
    .WBE_W         (1 ), 
    //.PAR_W         (MEM_W/8 ), 
//Chris Edit    .ECC_ENABLE    (1), 
// Byte Wide Write (8) not supported with ECC feature ON
    .ECC_ENABLE    (0), 
    .USE_URAM      (1), 
    .RDT_FFOUT     (MSG_MEM_FFOUT)           
  ) u_msg_mem(
  .clk (clk ), 
  .rst (rst ), 
  .we  (msg_mem.we  ), 
  .wad (msg_mem.wad ), 
  .wdt (msg_mem.wdt ), 
  .wpar(msg_mem.wpar), 
  .re  (msg_mem.re  ), 
  .rad (msg_mem.rad ), 
  .rdt (msg_mem.rdt ), 
  .rpar(msg_mem.rpar), 
  .sbe (msg_mem.sbe ), 
  .dbe (msg_mem.dbe )
);

/*******************************************************************************/
// interrupt vector lookup table
/*******************************************************************************/
qdma_v2_0_1_mailbox_xpm_sdpram_wrap 
  #(
    .MEM_W         (INTV_MEM_W), 
    .ADR_W         (INTV_MEM_ADR_W), 
    .WBE_W         (1 ), 
    .PAR_W         (2 ), 
//Chris EDit    .ECC_ENABLE    (1), 
    .ECC_ENABLE    (0), 
    .PARITY_ENABLE (0), 
    .RDT_FFOUT     (INTV_MEM_FFOUT)           
  ) u_int_vect_mem(
  .clk (clk ), 
  .rst (rst ), 
  .we  (intv_mem.we  ), 
  .wad (intv_mem.wad ), 
  .wdt (intv_mem.wdt ), 
  .wpar(intv_mem.wpar), 
  .re  (intv_mem.re  ), 
  .rad (intv_mem.rad ), 
  .rdt (intv_mem.rdt ), 
  .rpar(intv_mem.rpar), 
  .sbe (intv_mem.sbe ), 
  .dbe (intv_mem.dbe )
);

/*******************************************************************************/
//PF request queue instances
/*******************************************************************************/
genvar gi;

generate for(gi=0; gi<N_PF;gi++) begin :GEN_PF_REQQ
qdma_v2_0_1_mailbox_event_queue 
#(
  .QUEUE_DEPTH (N_FN),           // Event queue depth
  .EVENT_W     ($clog2(N_FN))    // Event queue data width
) u_pf_reqq (
  .clk         (clk), 
  .rst         (rst | pfq_rst[gi]), 
  .i_event     (pfq_push_event), 
  .i_push      (pfq_push[gi]), 
  .i_pop       (pfq_pop[gi]), 
  .o_event     (pfq_cur_event[gi]), 
  .o_vld       (pfq_cur_evld[gi]), 
  .eq_overflow (pfq_overflow[gi] ), 
  .eq_underflow(pfq_underflow[gi])
);
end
endgenerate

/*******************************************************************************/
//PF request queue instances
/*******************************************************************************/

qdma_v2_0_1_mailbox_int_ctrl
# (
   .N_PF            (N_PF            ),   // Number of PFs
   .N_FN            (N_FN            ),  // Total number of functions
   .USER_INT_VECT_W (USER_INT_VECT_W )  //Width of user interrupt vector
)
 u_mailbox_int_ctrl (
 .clk               (clk             ), 
 .rst               (rst             ), 
 .usr_irq_ack       (usr_irq_ack     ), 
 .usr_irq_fail      (usr_irq_fail    ), 
 .usr_irq_vld       (usr_irq_vld     ), 
 .usr_irq_vec       (usr_irq_vec     ), 
 .usr_irq_fnc       (usr_irq_fnc     ), 
 .fn_irq_en         (fn_irq_en       ), 
 .inte_vld          (inte_vld        ), 
 .inte_fnc          (inte_fnc        ), 
 .inte_ack          (inte_ack        ), 
 .irq_vect_rd       (irq_vect_rd     ), 
 .irq_vect_rd_addr  (irq_vect_rd_addr), 
 .irq_vect_rd_vld   (irq_vect_rd_vld ), 
 .irq_vect_rd_data  (irq_vect_rd_data)
);

endmodule 

`endif
