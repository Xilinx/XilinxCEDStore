`ifndef MAILBOX_USR_INT_MUX
`define MAILBOX_USR_INT_MUX

`timescale 1ns/1ps
/*******************************************************************************/
// mailbox_usr_int_mux.sv
//  1. parsing user interrupt to qdma
//  2. mux between two interrupt sources
/*******************************************************************************/
module qdma_v2_0_1_mailbox_usr_int_mux #(
  parameter USER_INT_VECT_W = 5,    // Width of user interrupt vector
  parameter N_FN            = 256   // Total number of functions
)(
 input                         clk,
 input                         rst,
 
 input                         usr_irq_ack,
 input                         usr_irq_fail, 
 output                        usr_irq_vld,
 output [USER_INT_VECT_W-1:0]  usr_irq_vec,
 output [$clog2(N_FN)-1:0]     usr_irq_fnc,

 output                        irq0_ack,
 output                        irq0_fail, 
 input                         irq0_vld,
 input  [USER_INT_VECT_W-1:0]  irq0_vec,
 input  [$clog2(N_FN)-1:0]     irq0_fnc,

 output                        irq1_ack,
 output                        irq1_fail, 
 input                         irq1_vld,
 input  [USER_INT_VECT_W-1:0]  irq1_vec,
 input  [$clog2(N_FN)-1:0]     irq1_fnc
  
);

logic irq_sel;
logic irq_proc; // busy flag, one irq interface is busy
logic irq_vld_int;

always_ff@(posedge clk)
  if(rst) 
    irq_sel <= '0;
  else 
    irq_sel <= irq_proc ? irq_sel :
               (irq0_vld & irq1_vld) ?  (~irq_sel) :
               irq0_vld ? 1'b0 :
               irq1_vld ? 1'b1 : 
                          irq_sel;
always_ff@(posedge clk)
  if(rst)
    irq_proc <= '0;
  else
    irq_proc <= (irq_proc & (irq0_ack | irq1_ack)) ? 1'b0 :
                (irq0_vld | irq1_vld) ? 1'b1 : irq_proc;

assign irq0_ack = (~irq_sel) & usr_irq_ack;
assign irq1_ack = irq_sel & usr_irq_ack;
assign irq0_fail = usr_irq_fail;
assign irq1_fail = usr_irq_fail;

assign usr_irq_vec = irq_sel ? irq1_vec : irq0_vec;
assign usr_irq_fnc = irq_sel ? irq1_fnc : irq0_fnc;

always_ff@(posedge clk)
  if(rst)
    irq_vld_int <= '0;
  else
    irq_vld_int <= (irq0_vld | irq1_vld);

assign usr_irq_vld = irq_vld_int;

endmodule
`endif

