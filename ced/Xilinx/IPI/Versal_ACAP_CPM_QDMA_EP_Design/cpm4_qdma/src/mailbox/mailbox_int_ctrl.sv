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

`ifndef MAILBOX_INT_CTRL_SV
`define MAILBOX_INT_CTRL_SV
`include "mailbox_defines.svh"
`timescale 1ns/1ps

module qdma_v2_0_1_mailbox_int_ctrl
# (
 parameter N_PF                  = 4,   // Number of PFs
 parameter N_FN                  = 256, // Total number of functions
 parameter USER_INT_VECT_W       = 5    //Width of user interrupt vector
)
(
 input                         clk,
 input                         rst,
 //Mailbox user interrupt interface
 input                         usr_irq_ack,
 input                         usr_irq_fail, 
 output                        usr_irq_vld,
 output [USER_INT_VECT_W-1:0]  usr_irq_vec,
 output [$clog2(N_FN)-1:0]     usr_irq_fnc,
 //
 input                         fn_irq_en [N_FN-1:0],
 input                         inte_vld, //interrupt event valid
 input [$clog2(N_FN)-1:0]      inte_fnc,
 output logic                  inte_ack,

 // interrupt vector read
 output logic                    irq_vect_rd,
 output logic [$clog2(N_FN)-1:0] irq_vect_rd_addr,
 input                           irq_vect_rd_vld,
 input  [USER_INT_VECT_W-1:0]    irq_vect_rd_data
);

typedef enum logic [8:0] {
  ST_IDLE           = 9'b1 ,
  ST_INTE_CHK       = 9'b1 << 1,
  ST_INTE_PUSH      = 9'b1 << 2,
  ST_INTE_ACK       = 9'b1 << 3,
  ST_IRQ_CHK        = 9'b1 << 4,
  ST_IRQ_GET_VECT   = 9'b1 << 5,
  ST_IRQ_WAIT_ACK   = 9'b1 << 6,
  ST_IRQ_POP        = 9'b1 << 7,
  ST_INTE_PUSH_BACK = 9'b1 << 8
} mailbox_int_fsm_type_e;

mailbox_int_fsm_type_e cur_fsm, nxt_fsm;

logic st_is_idle         ;
logic st_is_inte_chk     ;
logic st_is_inte_push    ;
logic st_is_inte_ack     ;
logic st_is_irq_chk      ;
logic st_is_irq_get_vect ;
logic st_is_irq_wait_ack ;
logic st_is_irq_pop      ;
logic st_is_inte_push_back;

assign  st_is_idle           = cur_fsm[0];
assign  st_is_inte_chk       = cur_fsm[1];
assign  st_is_inte_push      = cur_fsm[2];
assign  st_is_inte_ack       = cur_fsm[3];
assign  st_is_irq_chk        = cur_fsm[4];
assign  st_is_irq_get_vect   = cur_fsm[5];
assign  st_is_irq_wait_ack   = cur_fsm[6];
assign  st_is_irq_pop        = cur_fsm[7];
assign  st_is_inte_push_back = cur_fsm[8];

logic [$clog2(N_FN)-1:0] cur_fn;
logic [N_FN-1:0] inte_status; 
logic            inte_pending; //existing int event pending in the queue
logic            cur_fn_ie; //interrupt enable for the current fn at the top of the inte quene
logic push_back_en;


logic [$clog2(N_FN)-1:0] iq_fn;
logic                    iq_vld;
logic                    iq_overflow;
logic                    iq_underflow;
/*******************************************************************************/
// FSM
/*******************************************************************************/
always_ff@(posedge clk)
  if(rst)
    cur_fsm <= ST_IDLE;
  else 
    cur_fsm <= nxt_fsm;

always_comb begin
  nxt_fsm = cur_fsm;
  case (cur_fsm)
    ST_IDLE           : nxt_fsm = inte_vld ? ST_INTE_CHK :
                                  iq_vld   ? ST_IRQ_CHK  : cur_fsm ;
    ST_INTE_CHK       : nxt_fsm = (inte_pending) ? ST_INTE_ACK : ST_INTE_PUSH;
    ST_INTE_PUSH      : nxt_fsm = ST_INTE_ACK;
    ST_INTE_ACK       : nxt_fsm = ST_IDLE;
    
    ST_IRQ_CHK        : nxt_fsm = (cur_fn_ie) ? ST_IRQ_GET_VECT : ST_IRQ_POP;
    ST_IRQ_GET_VECT   : nxt_fsm = inte_vld          ? ST_INTE_CHK : 
                                  (irq_vect_rd_vld) ? ST_IRQ_WAIT_ACK : cur_fsm;
    ST_IRQ_WAIT_ACK   : nxt_fsm = (usr_irq_ack & ~usr_irq_fail) ? ST_IRQ_POP :
                                                                  cur_fsm;
    ST_IRQ_POP        : nxt_fsm = (push_back_en) ? ST_INTE_PUSH_BACK : ST_IDLE;    
    ST_INTE_PUSH_BACK : nxt_fsm = ST_IDLE;
  endcase 
end


always_ff@(posedge clk)
  if(rst)
    push_back_en <= 1'b0;
  else
    push_back_en <= st_is_idle ? 1'b0 :
                 //   (st_is_irq_chk & ~cur_fn_ie) ? 1'b1 :
                    (st_is_irq_wait_ack & usr_irq_ack & usr_irq_fail) ? 1'b1 : push_back_en;
//Notes: An interrupt event is discarded given the interrupt is disable. 

/*******************************************************************************/
// 
/*******************************************************************************/
always_ff@(posedge clk)
  if(rst)
    for(int i=0 ;i<N_FN;i++) 
      inte_status[i] <= 1'b0;
  else if (st_is_inte_push)
      inte_status[inte_fnc] <= 1'b1;
  else if (st_is_irq_pop) 
      inte_status[cur_fn] <= 1'b0;

always_ff@(posedge clk)
  if(rst)
    inte_pending <= '0;
  else 
    inte_pending <= inte_status[inte_fnc];

always_ff@(posedge clk)
  if(rst)
    cur_fn_ie <= '0;
  else 
    cur_fn_ie <= fn_irq_en[iq_fn];
//    cur_fn_ie <= fn_irq_en[cur_fn];

always_ff@(posedge clk)
  if(rst)
    cur_fn <= '0;
  else if (iq_vld)
    cur_fn <= iq_fn;


logic [USER_INT_VECT_W-1:0]  irq_vec_ff;

always_ff@(posedge clk)
  if(rst)
    irq_vec_ff <= '0;
  else if (irq_vect_rd_vld) 
    irq_vec_ff <= irq_vect_rd_data;
    
/*******************************************************************************/
// 
/*******************************************************************************/
assign usr_irq_vld = st_is_irq_wait_ack;
assign usr_irq_vec = irq_vec_ff;
assign usr_irq_fnc = cur_fn;

assign inte_ack    = st_is_inte_ack;

assign irq_vect_rd = st_is_irq_get_vect;
assign irq_vect_rd_addr = cur_fn;

/*******************************************************************************/
// PENDING interrupt queue
/*******************************************************************************/
wire                    intq_push  = st_is_inte_push | st_is_inte_push_back;
wire [$clog2(N_FN)-1:0] intq_event = st_is_inte_push_back ? cur_fn : inte_fnc;

qdma_v2_0_1_mailbox_event_queue 
#(
  .QUEUE_DEPTH (N_FN),           // Event queue depth
  .EVENT_W     ($clog2(N_FN))    // Event queue data width
) u_int_queue (
  .clk         (clk          ),
  .rst         (rst          ),
  .i_event     (intq_event   ),
  .i_push      (intq_push    ),
  .i_pop       (st_is_irq_pop),
  .o_event     (iq_fn        ),
  .o_vld       (iq_vld       ),
  .eq_overflow (iq_overflow  ),
  .eq_underflow(iq_underflow )
) ;

endmodule
`endif
