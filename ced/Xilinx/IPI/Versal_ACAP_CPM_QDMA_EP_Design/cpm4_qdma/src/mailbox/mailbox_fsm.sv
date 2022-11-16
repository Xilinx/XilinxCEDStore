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

`ifndef MAILBOX_FSM_SV
`define MAILBOX_FSM_SV
`include "mailbox_defines.svh"
`timescale 1ns/1ps

//TODO: add interrupt support
//TODO: invalid imsg read, when status is invalid
module qdma_v2_0_1_mailbox_fsm 
# (
 parameter N_PF               = 4,   // Number of PFs
 parameter N_FN               = 256, // Total number of functions
 parameter BAR_ID             = 0,   // Bar ID for mailbox, used for address decoding
 parameter MAX_MSG_SIZE       = 64,  // Maximum message size (Bytes)
 parameter VF_LEN_SIZE        = 7,   // Maximum memory space for a VF within a VFG (log2)
 parameter AXIL_ADDR_W        = 31,
 parameter AXIL_DATA_W        = 32,
 parameter AXIL_USER_W        = 29,
 parameter CSR_ADDR_W         = 10,
 parameter MSG_MEM_W          = 32,
 parameter MEM_RD_LATENCY     = 2,
 parameter INTV_MEM_W         = 8,
 parameter PF_ADDR_OFFSET     = 32'b0,
 parameter VF_ADDR_OFFSET     = 32'b0,
 parameter NUM_VFS_PF0        = 8,
 parameter NUM_VFS_PF1        = 8,
 parameter NUM_VFS_PF2        = 8,
 parameter NUM_VFS_PF3        = 8,
 parameter FIRSTVF_OFFSET_PF0 = 4,
 parameter FIRSTVF_OFFSET_PF1 = 11,
 parameter FIRSTVF_OFFSET_PF2 = 18,
 parameter FIRSTVF_OFFSET_PF3 = 25,
 parameter RTL_REVISION       = 32'h0,
 parameter PATCH_REVIVION     = 32'h0, 
 parameter USER_INT_VECT_W    = 5,  //Width of user interrupt vector
 parameter INTV_MEM_ADR_W     = $clog2(N_FN)
)
(
 input clk,
 input rst,
 
(*mark_debug*) mailbox_axi4lite_if.s              axi4l_s, 
 mailbox_xpm_sdpram_if.m            msg_mem,
 mailbox_xpm_sdpram_if.m            intv_mem, 
//PF Reqest event queue
 output logic                       pfq_push [N_PF-1:0], 
 output [$clog2(N_FN)-1:0]          pfq_push_event, 
 output logic                       pfq_pop [N_PF-1:0], 
 output logic                       pfq_rst [N_PF-1:0], 
 input  [$clog2(N_FN)-1:0]          pfq_cur_event [N_PF-1:0], 
 input                              pfq_cur_evld [N_PF-1:0], 
 input                              pfq_overflow [N_PF-1:0], 
 input                              pfq_underflow [N_PF-1:0],
 //mailbox to FLR request
 output                             mb2flr_push,
 output mailbox_mb2flr_data_t       mb2flr_data,
 input  [N_FN-1:0]                  flr_status,    

 input                              flr2mb_req, // flr request from flr to mb
 input  [$clog2(N_FN)-1:0]          flr2mb_fn,
 output                             flr2mb_ack,
 //interrupt controller I/F
 output                             fn_irq_en[N_FN-1:0],
 output                             inte_vld, //interrupt event valid
 output [$clog2(N_FN)-1:0]          inte_fnc,
 input                              inte_ack,

 // interrupt vector read
 input                              irq_vect_rd,
 input [$clog2(N_FN)-1:0]           irq_vect_rd_addr,
 output logic                       irq_vect_rd_vld,
 output logic [USER_INT_VECT_W-1:0] irq_vect_rd_data,
 output [11:0]                      dbg_out_csr_addr,
 output [19:0]                      dbg_out_debug_fsm
);

genvar gi, gj, gk;

localparam N_MSG_ENTRY=MAX_MSG_SIZE*8/MSG_MEM_W;

logic [AXIL_ADDR_W-1:0] axi4l_araddr_r;
logic [AXIL_ADDR_W-1:0] axi4l_awaddr_r;

mailbox_csr_addr_e    csr_addr;
mailbox_axil_user_t   axi4l_user_r;

logic [AXIL_DATA_W-1:0] rdata_mux, rdata_r;
logic [AXIL_DATA_W-1:0] wdata_r;

//logic req_int_en [N_FN-1:0]; 
//logic ack_int_en [N_FN-1:0];

logic int_icr [N_FN-1:0]; 
logic cur_int_icr;

logic i_msg_status [N_FN-1:0];
logic cur_i_msg_status;

logic pf_i_msg_status [N_PF-1:0];
logic vf_i_msg_status [N_FN-1:N_PF];

logic o_msg_status [N_FN-1:0];
logic cur_o_msg_status;
logic pf_o_msg_status [N_PF-1:0];
logic vf_o_msg_status [N_FN-1:N_PF];

//logic vf_reset_status [N_FN-1:0]; //TODO: add software reset control for VF

logic vf_i_msg_status_we;
logic [$clog2(N_FN)-1:0 ] vf_i_msg_status_addr;
logic vf_i_msg_status_wdata;

logic vf_o_msg_status_we;
logic [$clog2(N_FN)-1:0 ] vf_o_msg_status_addr;
logic vf_o_msg_status_wdata;


logic [$clog2(N_FN)-1:0] cur_fn;    //the current initiator FN
logic [$clog2(N_PF)-1:0] cur_pf;    //the current initiator PF
logic [$clog2(N_PF)-1:0] v2f_fn;    //the PF associated with the current VF
logic                    src_is_pf; //if current transaction source is a PF
logic [$clog2(N_FN)-1:0] target_fn_reg[N_PF-1:0]; 
logic [$clog2(N_FN)-1:0] target_fn; 
logic                    op_dir_p2p;       // A PF is talking to a PF target
logic                    op_dir_p2v;       // A PF is talking to a VF target
logic                    op_dir_v2p;       // A VF is talking to a PF target
logic [AXIL_DATA_W-1:0]  pf_ack_status [N_PF-1:0][N_FN/AXIL_DATA_W-1:0];
logic [AXIL_DATA_W-1:0]  pf_ack_rdata;
logic [N_FN/AXIL_DATA_W-1:0] pf_ack_vect [N_PF-1:0];
logic                    pf_ack_any [N_PF-1:0];  
logic                    cur_pf_ack_any;

logic                   rd_dt_vld;
logic                   reg_rd_vld;

logic [MEM_RD_LATENCY-1:0] intv_mem_rd_dly;
logic                      intv_mem_rd_vld;

logic [MEM_RD_LATENCY-1:0] msg_mem_rd_dly;
logic                      msg_mem_rd_vld;
logic [$clog2(N_FN) :0]    msg_mem_fn_rd_ofst;
logic [$clog2(N_FN) :0]    msg_mem_fn_wr_ofst;

//address decoding
//TODO: share address decoding for aw and ar channel for space
logic addr_is_imsg_mem;
logic addr_is_omsg_mem;
logic addr_is_intv;
logic addr_is_cmd;
logic addr_is_icr  ;
logic addr_is_pf_ack;
logic addr_is_target_fn;
logic addr_is_status;
logic addr_is_flr;
logic addr_is_rtl_rev;
logic addr_is_patch_rev;

logic raddr_decode_error;
logic waddr_decode_error;

localparam CMD_W = 4;
typedef enum logic [CMD_W-1:0] {
  CMD_NULL  = {{CMD_W-1{1'b0}},1'b0} ,
  CMD_SEND  = {{CMD_W-1{1'b0}},1'b1} ,
  CMD_RCV   = {{CMD_W-1{1'b0}},1'b1} << 1,
  CMD_POP   = {{CMD_W-1{1'b0}},1'b1} << 2,
  CMD_RESET = {{CMD_W-1{1'b0}},1'b1} << 3
} mailbox_cmd_type_e;


typedef enum logic [19:0] {
  ST_IDLE         = 20'b1 ,
  ST_ARADDR       = 20'b1 << 1,
  ST_ADDR_DEC     = 20'b1 << 2,
  ST_RD_DT        = 20'b1 << 3,
  ST_RDATA        = 20'b1 << 4,
  ST_AWADDR       = 20'b1 << 5,
  ST_WDATA        = 20'b1 << 6,
  ST_CMD          = 20'b1 << 7,
  ST_BRESP        = 20'b1 << 8,
  ST_ACK_LUT      = 20'b1 << 9, 
  ST_ACK_UPDATE   = 20'b1 << 10,
  ST_FLR_START    = 20'b1 << 11, //Fn decoding 
  ST_FLR_VF       = 20'b1 << 12, //vf i/o status, o_msg_mem
  ST_FLR_PF       = 20'b1 << 13, 
  ST_FLR_VFG      = 20'b1 << 14, //FLR VFs with VFG 
  ST_FLR_PF_PF    = 20'b1 << 15, //FLR VFs with VFG 
  ST_FLR_DONE     = 20'b1 << 16,
  ST_GET_INTV     = 20'b1 << 17,
  ST_INTV_DONE    = 20'b1 << 18,
  ST_SEND_INTE    = 20'b1 << 19 
} mailbox_fsm_type_e;

mailbox_fsm_type_e cur_fsm, nxt_fsm;
(*mark_debug*) wire [19:0] debug_fsm = cur_fsm;
//fsm decoding
logic st_is_idle  ;
logic st_is_araddr;
logic st_is_addr_dec;
logic st_is_rd_dt ;
logic st_is_rdata ;
logic st_is_awaddr;
logic st_is_wdata ;
logic st_is_cmd   ;
logic st_is_bresp ;
logic st_is_ack_lut;   
logic st_is_ack_update;
logic st_is_flr_start;
logic st_is_flr_vf   ;
logic st_is_flr_pf   ;
logic st_is_flr_vfg  ;
logic st_is_flr_done ;
logic st_is_get_intv ;
logic st_is_intv_done;
logic st_is_send_inte;

logic cmd_is_null ;

logic cmd_is_send ;
logic cmd_is_rcv  ;
//logic cmd_is_pop  ;
logic cmd_is_invalid; 
logic msg_mem_wr_error;


axi4l_opcode_e  cur_axitrans;
mailbox_cmd_type_e cur_cmd;

(*mark_debug*) logic [$clog2(N_FN)-1:0] vfg_first [N_PF-1:0];
(*mark_debug*) logic [$clog2(N_FN)-1:0] vfg_last  [N_PF-1:0];
(*mark_debug*) logic [$clog2(N_FN)-1:0] vfg_size  [N_PF-1:0];
(*mark_debug*) logic [$clog2(N_FN)-1:0] flr_fn;
(*mark_debug*) logic [$clog2(N_FN)-1:0] flr_target_fn;
(*mark_debug*) logic                    flr_is_pf;

logic clr_vf_omsg_done;
logic clr_pf_omsg_done;
logic clr_omsg_done;

logic [$clog2(N_MSG_ENTRY)-1:0] flr_omsg_ofst;
logic flr_vfg_done;

logic issue_int;
logic target_int_pnd;
logic cur_int_pnd;
logic [$clog2(N_FN)-1:0] cur_int_fn; 
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
    ST_IDLE      : nxt_fsm = (irq_vect_rd)                                                        ? ST_GET_INTV: 
                             (flr2mb_req)                                                         ? ST_FLR_START :
                             (axi4l_s.awvalid & ~((cur_axitrans == AXI4L_WR) & axi4l_s.arvalid))  ? ST_AWADDR :
                             (axi4l_s.arvalid)  ? ST_ARADDR : cur_fsm; 
    ST_ARADDR    : nxt_fsm = ST_ADDR_DEC;
    ST_ADDR_DEC  : nxt_fsm = (cur_axitrans == AXI4L_WR) ? ST_WDATA : ST_RD_DT;
    ST_RD_DT     : nxt_fsm = (rd_dt_vld | raddr_decode_error) ? ST_RDATA : cur_fsm;
    ST_RDATA     : nxt_fsm = (axi4l_s.rready) ? ST_IDLE : cur_fsm;
    ST_AWADDR    : nxt_fsm = ST_ADDR_DEC;
    ST_WDATA     : nxt_fsm = (axi4l_s.wvalid) ? ST_CMD : cur_fsm; 
    ST_CMD       : nxt_fsm = ((op_dir_v2p | op_dir_p2p) & cmd_is_rcv) | (cmd_is_null & addr_is_pf_ack) ? ST_ACK_LUT : ST_BRESP;
    ST_ACK_LUT   : nxt_fsm = ST_ACK_UPDATE;
    ST_ACK_UPDATE: nxt_fsm = ST_BRESP;
    ST_BRESP     : nxt_fsm = (axi4l_s.bready) ? (cur_int_icr & ((|cur_cmd) &target_int_pnd | (addr_is_icr & cur_int_pnd)) ? ST_SEND_INTE : ST_IDLE) : cur_fsm;
    ST_FLR_START : nxt_fsm = flr_is_pf ? ST_FLR_PF : ST_FLR_VF;
    ST_FLR_VF    : nxt_fsm = (clr_omsg_done) ? (flr_is_pf ? ST_FLR_VFG : ST_FLR_DONE) : cur_fsm;
    ST_FLR_PF    : nxt_fsm = (clr_pf_omsg_done) ? ST_FLR_VF : cur_fsm;
    ST_FLR_VFG   : nxt_fsm = (flr_vfg_done)  ? ST_FLR_PF_PF : ST_FLR_VF;
    ST_FLR_PF_PF : nxt_fsm = (clr_omsg_done) ? ST_FLR_DONE : cur_fsm;
    ST_FLR_DONE  : nxt_fsm = ST_IDLE;
    ST_GET_INTV  : nxt_fsm = (intv_mem_rd_dly) ? ST_INTV_DONE : cur_fsm; 
    ST_INTV_DONE : nxt_fsm = ST_IDLE;
    ST_SEND_INTE : nxt_fsm = (inte_ack) ? ST_IDLE : cur_fsm;
  endcase 
end

assign st_is_idle       = cur_fsm[0];
assign st_is_araddr     = cur_fsm[1];
assign st_is_addr_dec   = cur_fsm[2];
assign st_is_rd_dt      = cur_fsm[3];
assign st_is_rdata      = cur_fsm[4];
assign st_is_awaddr     = cur_fsm[5];
assign st_is_wdata      = cur_fsm[6];
assign st_is_cmd        = cur_fsm[7];
assign st_is_bresp      = cur_fsm[8];
assign st_is_ack_lut    = cur_fsm[9];   
assign st_is_ack_update = cur_fsm[10];
assign st_is_flr_start  = cur_fsm[11];
assign st_is_flr_vf     = cur_fsm[12];
assign st_is_flr_pf     = cur_fsm[13];
assign st_is_flr_vfg    = cur_fsm[14];  
assign st_is_flr_pf_pf  = cur_fsm[15];
assign st_is_flr_done   = cur_fsm[16];
assign st_is_get_intv   = cur_fsm[17];
assign st_is_intv_done  = cur_fsm[18];
assign st_is_send_inte  = cur_fsm[19];

/*******************************************************************************/
// FLR control 
/*******************************************************************************/

assign vfg_first[0] = FIRSTVF_OFFSET_PF0 + 'h0;
assign vfg_first[1] = FIRSTVF_OFFSET_PF1 + 'h1;
assign vfg_first[2] = FIRSTVF_OFFSET_PF2 + 'h2;
assign vfg_first[3] = FIRSTVF_OFFSET_PF3 + 'h3;

assign vfg_last[0] = FIRSTVF_OFFSET_PF0 + 'h0 + NUM_VFS_PF0-1;
assign vfg_last[1] = FIRSTVF_OFFSET_PF1 + 'h1 + NUM_VFS_PF1-1;
assign vfg_last[2] = FIRSTVF_OFFSET_PF2 + 'h2 + NUM_VFS_PF2-1;
assign vfg_last[3] = FIRSTVF_OFFSET_PF3 + 'h3 + NUM_VFS_PF3-1;

assign vfg_size[0] = NUM_VFS_PF0;
assign vfg_size[1] = NUM_VFS_PF1;
assign vfg_size[2] = NUM_VFS_PF2;
assign vfg_size[3] = NUM_VFS_PF3;

always_ff @(posedge clk)
  if(rst) 
    flr_is_pf <= '0;
  else 
    flr_is_pf <= st_is_idle & (~|flr2mb_fn[$bits(cur_fn)-1:$clog2(N_PF)]) ? 1'b1 :
                 st_is_idle                                               ? 1'b0 : flr_is_pf;

always_ff @(posedge clk)
  if(rst) 
    flr_fn <= '0;
  else 
    flr_fn <= st_is_flr_start ? flr2mb_fn : flr_fn;

always_ff @(posedge clk)
  if(rst)
    flr_target_fn <= '0;
  else 
    flr_target_fn <= (st_is_flr_start & ~flr_is_pf)                    ? flr2mb_fn :
                     (st_is_flr_vfg & flr_vfg_done)                    ? flr_fn :
                     (st_is_flr_start & flr_is_pf)                     ? vfg_first[flr_fn[$clog2(N_PF)-1:0]] :
                     (st_is_flr_pf & clr_pf_omsg_done)                 ? vfg_first[flr_fn[$clog2(N_PF)-1:0]] : 
                     (st_is_flr_vfg | (st_is_flr_pf & clr_omsg_done))  ? (flr_target_fn + 1'b1)  : flr_target_fn;

always_ff @(posedge clk)
  if(rst)
    flr_omsg_ofst <= '0;
  else 
    flr_omsg_ofst <= (st_is_flr_pf | st_is_flr_vf | st_is_flr_pf_pf) ? (flr_omsg_ofst + 1'b1) :'0;

assign clr_omsg_done = (&flr_omsg_ofst);

assign clr_pf_omsg_done = flr_vfg_done & clr_omsg_done;
assign flr_vfg_done     = (flr_target_fn == vfg_last[flr_fn[$clog2(N_PF)-1:0]]);
assign flr2mb_ack       = st_is_flr_done;
/*******************************************************************************/
// AXI4LITE  Operation
/*******************************************************************************/
always_ff@(posedge clk)
  if(rst) begin
    axi4l_araddr_r <= '0;
    axi4l_awaddr_r <= '0;
  end else begin
    axi4l_araddr_r <= st_is_idle ? axi4l_s.araddr : axi4l_araddr_r;
    axi4l_awaddr_r <= st_is_idle ? axi4l_s.awaddr : axi4l_awaddr_r;
  end

always_ff@(posedge clk)
  if(rst)
    cur_axitrans <= AXI4L_RD;
  else
    cur_axitrans <= st_is_awaddr ? AXI4L_WR :
                    st_is_araddr ? AXI4L_RD: cur_axitrans;

assign axi4l_s.awready = st_is_awaddr;

//address decoding
always_ff@(posedge clk)
  if(rst) begin
    csr_addr <= FN_STATUS_A;
  end else begin
    csr_addr <= st_is_araddr ? fn_axi2csr_addr(axi4l_s.aruser[$clog2(N_FN)-1:0], axi4l_araddr_r) : 
                st_is_awaddr ? fn_axi2csr_addr(axi4l_s.awuser[$clog2(N_FN)-1:0], axi4l_awaddr_r) : csr_addr;
  end

//CSR address decoding
always_ff@(posedge clk)
  if(rst) begin
    addr_is_status    <= 1'b0;
    addr_is_cmd       <= 1'b0;
    addr_is_target_fn <= 1'b0;
    addr_is_icr       <= 1'b0;
    addr_is_imsg_mem  <= 1'b0;
    addr_is_omsg_mem  <= 1'b0;
    addr_is_intv      <= 1'b0;
    addr_is_pf_ack    <= 1'b0;
    addr_is_flr       <= 1'b0;
    addr_is_rtl_rev   <= 1'b0;
    addr_is_patch_rev <= 1'b0;
  end else if (st_is_addr_dec) begin
    addr_is_status    <= (csr_addr == FN_STATUS_A);
    addr_is_cmd       <= (csr_addr == FN_CMD_A);
    addr_is_target_fn <= (csr_addr == TARGET_FN_A);
    addr_is_icr       <= (csr_addr == ICR_A);
    addr_is_intv      <= (csr_addr == FN_INT_VECT_A);
    addr_is_rtl_rev   <= (csr_addr == RTL_REV_A);
    addr_is_patch_rev <= (csr_addr == PATCH_REV_A);
    addr_is_pf_ack    <= (csr_addr >= PF_ACK_A0) & (csr_addr <= PF_ACK_A7);
    addr_is_flr       <= (csr_addr == FN_FLR_CTRL_A);
    addr_is_imsg_mem  <= (csr_addr >= I_MSG_MEM_A0 ) & (csr_addr < O_MSG_MEM_A0);
    addr_is_omsg_mem  <= (csr_addr >= O_MSG_MEM_A0) & (csr_addr < MAX_ADDR_A);
end

always_ff@(posedge clk) 
  if(rst)
    raddr_decode_error <= '0;
  else 
    raddr_decode_error <= st_is_rd_dt & ~(
                          addr_is_status   |
                          addr_is_target_fn|
                          addr_is_icr      |
                          addr_is_imsg_mem |
                          addr_is_omsg_mem |
                          addr_is_intv |
                          addr_is_pf_ack   |
                          addr_is_rtl_rev  |
                          addr_is_patch_rev |
                          addr_is_flr        );

always_ff@(posedge clk) 
  if(rst)
    waddr_decode_error <= '0;
  else 
    waddr_decode_error <= st_is_wdata & ~(
                          addr_is_status   |
                          addr_is_cmd      |
                          addr_is_target_fn|
                          addr_is_icr      |
                          addr_is_imsg_mem |
                          addr_is_omsg_mem |
                          addr_is_intv |
                          addr_is_pf_ack   |
                          addr_is_flr       );

//user field decoding
always_ff@(posedge clk)
  if(rst) begin
    axi4l_user_r   <= '0;
  end else if (st_is_araddr) begin
    axi4l_user_r <= mailbox_axil_user_t'(axi4l_s.aruser);
  end else if (st_is_awaddr) begin
    axi4l_user_r <= mailbox_axil_user_t'(axi4l_s.awuser);
  end

assign cur_fn = axi4l_user_r.func;
assign cur_pf = cur_fn[$clog2(N_PF)-1:0];
assign v2f_fn = axi4l_user_r.vfg;

always_ff@(posedge clk)
  if(rst) begin
    src_is_pf <= '0;
  end else begin
    src_is_pf <= st_is_addr_dec ? (~|cur_fn[$bits(cur_fn)-1:$clog2(N_PF)]) : src_is_pf;
  end

//read channel 
assign axi4l_s.arready = st_is_araddr;
assign axi4l_s.rvalid  = st_is_rdata;
assign axi4l_s.ruser   = axi4l_user_r;
assign axi4l_s.rresp   = {1'b0,raddr_decode_error};     
assign axi4l_s.rdata   = rdata_r; 

//write channel
assign axi4l_s.buser  = axi4l_user_r;
assign axi4l_s.bvalid = st_is_bresp;
assign axi4l_s.bresp  = { (cmd_is_invalid | msg_mem_wr_error), waddr_decode_error}; //TODO, add slv_error
assign axi4l_s.wready = st_is_cmd;

always_ff@(posedge clk)
  wdata_r <= (st_is_wdata & axi4l_s.wvalid) ? axi4l_s.wdata : wdata_r;


always_ff@(posedge clk) begin
//  target_fn <=  src_is_pf ? target_fn_reg[cur_pf] : {{$bits(target_fn){1'b0}},v2f_fn}; // code change to accomodate wr_data one cycle earlier , refer XDMA-481

  target_fn <=  st_is_addr_dec ? ( (~|cur_fn[$bits(cur_fn)-1:$clog2(N_PF)]) ) ? target_fn_reg[cur_pf] : {{$bits(target_fn){1'b0}},v2f_fn}:
                                 target_fn;
end

wire target_is_pf = ~|target_fn[$bits(target_fn)-1:$clog2(N_PF)];

always_ff@(posedge clk) 
  if(rst) begin
    op_dir_p2p <= '0;
    op_dir_p2v <= '0;
    op_dir_v2p <= '0;
  end else begin 
    op_dir_p2p <= (src_is_pf & target_is_pf);
    op_dir_p2v <= (src_is_pf & ~target_is_pf);
    op_dir_v2p <= (~src_is_pf);
  end

always_ff@(posedge clk)
   if(rst) 
     for(int i=0;i<N_PF;i++)
        target_fn_reg[i] <= '0; 
   else if(addr_is_target_fn & st_is_cmd)
     target_fn_reg[cur_pf] <= wdata_r[$bits(target_fn_reg)-1:0];

// read data
assign rdata_mux = (addr_is_imsg_mem & cur_i_msg_status ) ?  {{AXIL_DATA_W{1'b0}}, msg_mem.rdt} :
                   addr_is_omsg_mem ? {{AXIL_DATA_W{1'b0}}, msg_mem.rdt} :
                   addr_is_intv     ? {{AXIL_DATA_W{1'b0}}, intv_mem.rdt} :
                   addr_is_status   ? {{AXIL_DATA_W{1'b0}}, 
                                        1'b0,     //TODO: src_is_pf & vf_reset_status[target_fn],
                                        {$clog2(N_FN){src_is_pf}} & pfq_cur_event[cur_pf],
                                        1'b0,
                                        cur_pf_ack_any,
                                        cur_o_msg_status,
                                        cur_i_msg_status} :
                   addr_is_target_fn?  target_fn :
                   addr_is_pf_ack   ?  pf_ack_rdata :
                   addr_is_flr      ?  {32'b0,flr_status[cur_fn]}:
                   addr_is_rtl_rev  ?  RTL_REVISION :
                   addr_is_patch_rev?  PATCH_REVIVION :
                   addr_is_icr      ? {{AXIL_DATA_W{1'b0}}, cur_int_icr } : '0; //TODO, interrupt status

assign rd_dt_vld =  intv_mem_rd_vld | msg_mem_rd_vld | reg_rd_vld;

always_ff@(posedge clk)
  rdata_r <= rdata_mux;

always_ff@(posedge clk)
  if(rst)
    reg_rd_vld  <= '0;
  else 
    reg_rd_vld  <= (cur_axitrans == AXI4L_RD) & st_is_rd_dt & !(addr_is_imsg_mem | addr_is_omsg_mem | addr_is_intv);


/*******************************************************************************/
// FN Status operation
/*******************************************************************************/
assign cmd_is_null  = ~|cur_cmd;
assign cmd_is_send  = (cur_cmd == 4'b0001);
assign cmd_is_rcv   = (cur_cmd == 4'b0010);
//assign cmd_is_pop   = (cur_cmd == 4'b0100);

always_ff@(posedge clk)
  cmd_is_invalid <= ~(cmd_is_null | cmd_is_send | cmd_is_rcv);

always_ff@(posedge clk)
  if(rst)
    cur_cmd <= CMD_NULL;
  else
    cur_cmd <= (st_is_wdata & addr_is_cmd & axi4l_s.wvalid) ? mailbox_cmd_type_e'(axi4l_s.wdata[CMD_W-1:0]) :
                st_is_idle ? CMD_NULL : cur_cmd;
    
//i_msg_status : distributed RAM
assign pf_i_msg_status = pfq_cur_evld;
assign i_msg_status = {vf_i_msg_status,pf_i_msg_status};
assign cur_i_msg_status = i_msg_status[cur_fn];

wire cmd_ack = cmd_is_rcv;
assign vf_i_msg_status_we =  st_is_flr_vf                ? 1'b1 : 
                             ~st_is_cmd                  ? 1'b0 :
                             st_is_flr_vf                ? 1'b1 : 
                             (cmd_is_send  & op_dir_p2v) ? 1'b1 :
                             (cmd_is_send  & op_dir_v2p) ? 1'b0 :
                             (cmd_is_send  & op_dir_p2p) ? 1'b0 :
                             (cmd_ack      & op_dir_p2v) ? 1'b0 :
                             (cmd_ack      & op_dir_p2p) ? 1'b0 :
                             (cmd_ack      & op_dir_v2p) ? 1'b1 :
                             1'b0;
assign vf_i_msg_status_addr= st_is_flr_vf                ? flr_target_fn :
                             (cmd_is_send  & op_dir_p2v) ? target_fn :
                             //(cmd_is_send  & op_dir_v2p) ? 1'b0 :
                             //(cmd_is_send  & op_dir_p2p) ? 1'b0 :
                             //(cmd_ack      & op_dir_p2v) ? 1'b0 :
                             //(cmd_ack      & op_dir_p2p) ? 1'b0 :
                             (cmd_ack      & op_dir_v2p) ? cur_fn :
                             cur_fn;                             
assign vf_i_msg_status_wdata = st_is_flr_vf                ? 1'b0 :
                               (cmd_is_send  & op_dir_p2v) ? 1'b1 :
                              // (cmd_is_send  & op_dir_v2p) ? 1'b0 :
                              // (cmd_is_send  & op_dir_p2p) ? 1'b0 :
                              // (cmd_ack      & op_dir_p2v) ? 1'b0 :
                              // (cmd_ack      & op_dir_p2p) ? 1'b0 :
                               (cmd_ack      & op_dir_v2p) ? 1'b0 :
                               1'b0;

always_ff@(posedge clk)
  if(rst)
    for(int i=N_PF;i<N_FN;i++) 
      vf_i_msg_status[i] <= 1'b0;
   else if (vf_i_msg_status_we)
      vf_i_msg_status[vf_i_msg_status_addr] <= vf_i_msg_status_wdata;

//o_msg_status : distributed RAM
//assign pf_o_msg_status = {N_PF{i_msg_status[target_fn]}}; //TODO
generate for(gi=0;gi<N_PF;gi++) begin:GEN_PF_O_MSG_STATUS
  assign pf_o_msg_status[gi] =i_msg_status[target_fn];
end
endgenerate 
  
assign o_msg_status = {vf_o_msg_status,pf_o_msg_status};
assign cur_o_msg_status = o_msg_status[cur_fn];
assign vf_o_msg_status_we = (st_is_flr_pf_pf) ? 1'b1: 
                            (st_is_flr_vf)    ? 1'b1 :
                             ~st_is_cmd ? 1'b0 : 
                             (cmd_is_send & op_dir_p2p ) ? 1'b1 :
                            // (cmd_is_send & op_dir_p2v ) ? 1'b0 : //i_msg_memory ops
                             (cmd_is_send & op_dir_v2p ) ? 1'b1 : 
                             (cmd_is_rcv & op_dir_p2p ) ? 1'b1 :
                             (cmd_is_rcv & op_dir_p2v ) ? 1'b1 : 
                             //(cmd_is_rcv & op_dir_v2p ) ? 1'b0 : //i_msg_memory ops
                              1'b0;
                             
assign vf_o_msg_status_addr =  st_is_flr_pf_pf             ? flr_fn:
                               st_is_flr_vf                ? flr_target_fn :
                               (cmd_is_send & op_dir_p2p ) ? cur_fn    :
                            // (cmd_is_send & op_dir_p2v ) ? target_fn : //i_msg_memory ops
                               (cmd_is_send & op_dir_v2p ) ? cur_fn    : 
                               (cmd_is_rcv & op_dir_p2p )  ? target_fn :
                               (cmd_is_rcv & op_dir_p2v )  ? target_fn : 
                            //   (cmd_is_rcv & op_dir_v2p )  ? 1'b0 : //i_msg_memory ops
                                cur_fn;

assign vf_o_msg_status_wdata =  (st_is_flr_vf |st_is_flr_pf_pf) ? 1'b0 :
                                (cmd_is_send & op_dir_p2p ) ? 1'b1 :
                            // (cmd_is_send & op_dir_p2v ) ? 1'b0 : //i_msg_memory ops
                                (cmd_is_send & op_dir_v2p ) ? 1'b1 : 
                                (cmd_is_rcv & op_dir_p2p ) ? 1'b0 :
                                (cmd_is_rcv & op_dir_p2v ) ? 1'b0 : 
                             //(cmd_is_rcv & op_dir_v2p ) ? 1'b0 : //i_msg_memory ops
                                1'b0;

always_ff@(posedge clk)
  if(rst)
    for(int i=N_PF;i<N_FN;i++) 
      vf_o_msg_status[i] <= 1'b0;
   else if (vf_o_msg_status_we)
      vf_o_msg_status[vf_o_msg_status_addr] <= vf_o_msg_status_wdata;

//pf_ack_status 
wire [AXIL_DATA_W-1:0]              pf_ack_data_nxt, pf_ack_bitmask;
wire [$clog2(N_FN/AXIL_DATA_W)-1:0] pf_ack_reg_ofst;
wire [$clog2(AXIL_DATA_W)-1:0]      pf_ack_reg_bit_ofst;
wire [$clog2(N_PF)-1:0]             pf_ack_fn_addr;
assign pf_ack_fn_addr  = (op_dir_v2p & cmd_is_rcv) ? v2f_fn :
                         (op_dir_p2p & cmd_is_rcv) ? target_fn[$clog2(N_PF)-1:0] : cur_fn[$clog2(N_PF)-1:0];

assign pf_ack_reg_ofst = (op_dir_v2p) ? cur_fn[$bits(cur_fn)-1: $bits(pf_ack_reg_bit_ofst)] :
                         (op_dir_p2p & cmd_is_rcv) ?  cur_fn[$bits(cur_fn)-1: $bits(pf_ack_reg_bit_ofst)] : csr_addr[$bits(pf_ack_reg_ofst)-1:0] ;
assign pf_ack_reg_bit_ofst = (op_dir_v2p & cmd_is_rcv) ?  cur_fn[$bits(pf_ack_reg_bit_ofst) : 0] :
                             (op_dir_p2p & cmd_is_rcv) ? target_fn[$bits(pf_ack_reg_bit_ofst):0] : '0;
assign pf_ack_bitmask  = fn_32_bin2onehot(pf_ack_reg_bit_ofst);

assign pf_ack_data_nxt = addr_is_pf_ack ? (pf_ack_rdata & (~wdata_r)) : (pf_ack_rdata | pf_ack_bitmask);
                         
always_ff@(posedge clk) 
  if(rst)
    for(int i=0;i<N_PF;i++)
      for(int j=0;j<(N_FN/AXIL_DATA_W);j++)
        pf_ack_status[i][j] <= '0;
  else if (st_is_ack_update) 
        pf_ack_status[pf_ack_fn_addr][pf_ack_reg_ofst] <= pf_ack_data_nxt;

always_ff@(posedge clk)
  if(rst)
    pf_ack_rdata <= '0;
  else if (st_is_rd_dt | st_is_ack_lut)
    pf_ack_rdata <=  pf_ack_status[pf_ack_fn_addr][pf_ack_reg_ofst];

always_ff@(posedge clk)  
  if(rst)
    for(int i=0;i<N_PF;i++)
      for(int j=0;j<(N_FN/AXIL_DATA_W);j++)
        pf_ack_vect[i][j] <= '0;
  else if (st_is_ack_update) 
        pf_ack_vect[pf_ack_fn_addr][pf_ack_reg_ofst] <= |(pf_ack_data_nxt);

generate for(gi=0;gi<N_PF;gi++) begin :GEN_PF_ACK_ANY
  always_ff@(posedge clk)
    if(rst)
      pf_ack_any[gi] <= 1'b0;
    else 
      pf_ack_any[gi] <= |pf_ack_vect[gi];
end
endgenerate

assign cur_pf_ack_any = src_is_pf & pf_ack_any[cur_pf];
/*******************************************************************************/
// PF event queue control
/*******************************************************************************/
assign pfq_push_event = cur_fn;
generate for (gi=0;gi<N_PF;gi++) begin :GEN_PFQ_PUSH
  always_ff@(posedge clk)
    if(rst)
      pfq_push[gi] <= '0;
    else
      pfq_push[gi] <=  st_is_cmd & cmd_is_send & (~op_dir_p2v) & 
                       (target_fn[$clog2(N_PF)-1:0] == gi) & 
                       ~cur_o_msg_status;
end
endgenerate 

generate for (gi=0;gi<N_PF;gi++) begin :GEN_PFG_POP
  always_ff@(posedge clk)
    if(rst)
      pfq_pop[gi] <= '0;
    else
      pfq_pop[gi] <=  st_is_cmd & cmd_is_rcv & (src_is_pf) & (cur_fn[$clog2(N_PF)-1:0] == gi);

  always_ff@(posedge clk)
    if(rst)
      pfq_rst[gi] <= '0;
    else
      pfq_rst[gi] <= st_is_flr_done & flr_is_pf & (flr_fn[$clog2(N_PF)-1:0] == gi);

end
endgenerate

/*******************************************************************************/
// interrupt 
/*******************************************************************************/
always_ff@(posedge clk)
  if(rst)
    for(int i=0;i<N_FN;i++) 
      int_icr[i] <= 1'b0; 
   else if (addr_is_icr & st_is_cmd)
      int_icr[cur_fn] <= wdata_r[0];

always_ff@(posedge clk)
  if(rst)
    issue_int <= '0;
  else if (st_is_idle) 
    issue_int <= '0;
  else
    issue_int <= (st_is_cmd & (cmd_is_rcv | cmd_is_send | addr_is_icr)) ? 1'b1: issue_int;

always_ff@(posedge clk)
  if(rst)
    target_int_pnd <= '0;
  else if (st_is_idle) 
    target_int_pnd <= '0;
  else
    target_int_pnd <= (st_is_cmd & (cmd_is_rcv | cmd_is_send)) ? 1'b1: target_int_pnd;

always_ff@(posedge clk)
  if(rst)
    cur_int_pnd <= '0;
  else
    cur_int_pnd <= cur_pf_ack_any | cur_i_msg_status;
    
wire [$clog2(N_FN)-1:0] cur_int_fn_nxt; 

assign cur_int_fn_nxt =  st_is_cmd ? ((cmd_is_rcv | cmd_is_send) ? target_fn : cur_fn)
                                   : cur_int_fn;

always_ff@(posedge clk) begin
  if(rst)
    cur_int_fn <= '0;
  else
    cur_int_fn <= cur_int_fn_nxt;
//   cur_int_fn <= st_is_cmd ? ((cmd_is_rcv | cmd_is_send) ? target_fn : cur_fn)
//                           : cur_int_fn; 
end


always_ff@(posedge clk)
  if(rst)
    cur_int_icr <= '0;
  else
    cur_int_icr <= int_icr[cur_int_fn_nxt];
//    cur_int_icr <= int_icr[cur_int_fn];

assign inte_fnc  = cur_int_fn;
assign inte_vld  = st_is_send_inte;
assign fn_irq_en = int_icr;
/*******************************************************************************/
// FN interrupt vector lookup
/*******************************************************************************/
always_ff@(posedge clk)
  if(rst)
    intv_mem.re <= '0;
  else
    intv_mem.re <= ((cur_axitrans == AXI4L_RD) & st_is_rd_dt & addr_is_intv) | 
                   (st_is_idle && irq_vect_rd);

always_ff@(posedge clk)
  if(rst)
    intv_mem_rd_dly <= '0;
  else
    intv_mem_rd_dly <= {intv_mem_rd_dly[$bits(intv_mem_rd_dly)-2:0],intv_mem.re};

assign intv_mem_rd_vld = intv_mem_rd_dly[$bits(intv_mem_rd_dly)-1];

//assign intv_mem.rad = st_is_get_intv ? irq_vect_rd_addr : target_fn;
assign intv_mem.rad = (st_is_rd_dt & addr_is_intv) ? cur_fn :
		      st_is_get_intv ? irq_vect_rd_addr : target_fn; 
    
assign intv_mem.we  = st_is_cmd & addr_is_intv;
assign intv_mem.wdt = wdata_r[INTV_MEM_W-1:0];
//assign intv_mem.wad = target_fn;
assign intv_mem.wad = cur_fn;
assign intv_mem.wpar = 1'b0;

//To interrupt controller
assign irq_vect_rd_vld  = st_is_intv_done;
assign irq_vect_rd_data = intv_mem.rdt;
/*******************************************************************************/
// I/O msg memory 
/*******************************************************************************/
always_ff@(posedge clk)
  if(rst)
    msg_mem.re <= '0;
  else
    msg_mem.re <= (cur_axitrans == AXI4L_RD) & st_is_rd_dt & (addr_is_omsg_mem | addr_is_imsg_mem);

always_ff@(posedge clk)
  if(rst)
    msg_mem_rd_dly <= '0;
  else
    msg_mem_rd_dly <= {msg_mem_rd_dly[$bits(msg_mem_rd_dly)-2:0],msg_mem.re};

assign msg_mem_rd_vld = msg_mem_rd_dly[$bits(msg_mem_rd_dly)-1];

assign msg_mem_fn_rd_ofst = (op_dir_p2p & addr_is_omsg_mem) ? {1'b1, cur_fn} :
                            (op_dir_p2p & addr_is_imsg_mem) ? {1'b1, target_fn} :
                            (op_dir_p2v & addr_is_omsg_mem) ? {1'b0, target_fn} :
                            (op_dir_p2v & addr_is_imsg_mem) ? {1'b1, target_fn} :
                            (op_dir_v2p & addr_is_omsg_mem) ? {1'b1, cur_fn} : 
                            (op_dir_v2p & addr_is_imsg_mem) ? {1'b0, cur_fn} : target_fn; 

assign msg_mem_fn_wr_ofst = st_is_flr_vf                    ? {1'b1, flr_target_fn} :
                            st_is_flr_pf                    ? {1'b0, flr_target_fn} :
                            st_is_flr_pf_pf                 ? {1'b1, flr_target_fn} :
                            (op_dir_p2p & addr_is_omsg_mem) ? {1'b1, cur_fn} :
                           // (op_dir_p2p & addr_is_imsg_mem) ? {1'b1, target_fn} :
                            (op_dir_p2v & addr_is_omsg_mem) ? {1'b0, target_fn} :
                           // (op_dir_p2v & addr_is_imsg_mem) ? {1'b0, target_fn} :
                            (op_dir_v2p & addr_is_omsg_mem) ? {1'b1, cur_fn} : 
                           // (op_dir_v2p & addr_is_imsg_mem) ? {1'b0, cur_fn}
                                                                              target_fn; 


wire [$clog2(N_MSG_ENTRY)-1:0] msg_r_ofst =  csr_addr[$clog2(N_MSG_ENTRY) -1 : 0] ;
assign msg_mem.rad = {msg_mem_fn_rd_ofst, msg_r_ofst};
    
assign msg_mem.we =  (st_is_flr_vf | st_is_flr_pf | st_is_flr_pf_pf)  | 
                     (st_is_cmd & (addr_is_omsg_mem) & 
                    // (st_is_cmd & (addr_is_omsg_mem | addr_is_imsg_mem) & 
                     ~(op_dir_v2p & cur_o_msg_status) &
                     ~(op_dir_p2v & i_msg_status[target_fn]) &
                     ~(op_dir_p2p & cur_o_msg_status));


assign msg_mem_wr_error = st_is_cmd & (addr_is_omsg_mem | addr_is_imsg_mem) & 
                     ((op_dir_v2p & cur_o_msg_status) |
                      (op_dir_p2v & i_msg_status[target_fn]) |
                      (op_dir_p2p & cur_o_msg_status));

assign msg_mem.wdt  = (st_is_flr_vf | st_is_flr_pf | st_is_flr_pf_pf) ? '0 : wdata_r;
wire [$clog2(N_MSG_ENTRY)-1:0] msg_w_ofst = (st_is_flr_vf | st_is_flr_pf | st_is_flr_pf_pf) ?  flr_omsg_ofst : csr_addr[$clog2(N_MSG_ENTRY) -1 : 0] ;
assign msg_mem.wad  = {msg_mem_fn_wr_ofst, msg_w_ofst};
assign msg_mem.wpar = 1'b0;

/*******************************************************************************/
// MB2FLR 
/*******************************************************************************/
assign mb2flr_data.data = wdata_r;
assign mb2flr_data.func = axi4l_user_r.func;
assign mb2flr_data.vfg  = axi4l_user_r.vfg;

assign mb2flr_push = addr_is_flr & st_is_cmd;


/*******************************************************************************/
// Functions
/*******************************************************************************/
function [AXIL_DATA_W-1:0] fn_32_bin2onehot;
  input [4:0] bin;
  begin
  case(bin) 
    0 :  fn_32_bin2onehot =  32'h0001 << 0;
    1 :  fn_32_bin2onehot =  32'h0001 <<  1;
    2 :  fn_32_bin2onehot =  32'h0001 <<  2;
    3 :  fn_32_bin2onehot =  32'h0001 <<  3;
    4 :  fn_32_bin2onehot =  32'h0001 <<  4;
    5 :  fn_32_bin2onehot =  32'h0001 <<  5;
    6 :  fn_32_bin2onehot =  32'h0001 <<  6;
    7 :  fn_32_bin2onehot =  32'h0001 <<  7;
    8 :  fn_32_bin2onehot =  32'h0001 <<  8;
    9 :  fn_32_bin2onehot =  32'h0001 <<  9;
   10 :  fn_32_bin2onehot =  32'h0001 << 10;
   11 :  fn_32_bin2onehot =  32'h0001 << 11;
   12 :  fn_32_bin2onehot =  32'h0001 << 12;
   13 :  fn_32_bin2onehot =  32'h0001 << 13;
   14 :  fn_32_bin2onehot =  32'h0001 << 14;
   15 :  fn_32_bin2onehot =  32'h0001 << 15;
   16 :  fn_32_bin2onehot =  32'h0001 << 16;
   17 :  fn_32_bin2onehot =  32'h0001 << 17;
   18 :  fn_32_bin2onehot =  32'h0001 << 18;
   19 :  fn_32_bin2onehot =  32'h0001 << 19;
   20 :  fn_32_bin2onehot =  32'h0001 << 20;
   21 :  fn_32_bin2onehot =  32'h0001 << 21;
   22 :  fn_32_bin2onehot =  32'h0001 << 22;
   23 :  fn_32_bin2onehot =  32'h0001 << 23;
   24 :  fn_32_bin2onehot =  32'h0001 << 24;
   25 :  fn_32_bin2onehot =  32'h0001 << 25;
   26 :  fn_32_bin2onehot =  32'h0001 << 26;
   27 :  fn_32_bin2onehot =  32'h0001 << 27;
   28 :  fn_32_bin2onehot =  32'h0001 << 28;
   29 :  fn_32_bin2onehot =  32'h0001 << 29;
   30 :  fn_32_bin2onehot =  32'h0001 << 30;
   31 :  fn_32_bin2onehot =  32'h0001 << 31;
  endcase
  end
endfunction

function mailbox_csr_addr_e fn_axi2csr_addr;
  input [$clog2(N_FN)-1:0] fn;
  input [AXIL_ADDR_W-1:0]  axi4l_addr;
  logic [AXIL_ADDR_W-1:0]  fn_ofst;
  logic [AXIL_ADDR_W-1:0]  csr_addr;
  begin
    fn_ofst  =  (|fn[$bits(fn)-1:$clog2(N_PF)]) ? VF_ADDR_OFFSET : PF_ADDR_OFFSET; //VF
    csr_addr =  axi4l_addr - fn_ofst;
    fn_axi2csr_addr = mailbox_csr_addr_e'(csr_addr[CSR_ADDR_W+2-1:2]); //TODO, add the actually translate function
  end
endfunction

assign dbg_out_csr_addr  = csr_addr;
assign dbg_out_debug_fsm = debug_fsm;

endmodule

`endif
 

