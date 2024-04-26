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
`timescale 1ns / 1ps
`include "cdx5n_defines.svh"
`include "cdx5n_csi_defines.svh"
`include "ks_global_interfaces_def.sv"


module credit_manager #
(
    parameter TCQ                   = 0,
    parameter CRDT_CNTR_WIDTH       = 13,
    parameter DELAY_WIDTH           = 4,
    parameter DELAY_CNTR_WIDTH      = 11,
    parameter DEST_CRDT_WIDTH       = 13,//Max no.of type0 credits that can be returned in a cycle
    parameter TYPE0_CNTR_WIDTH      = 13,//Width of internal credit counters
    parameter DST_FIFO_ID_WIDTH     = 7,
    parameter DELAY_VALUE           = 8,
    parameter NUM_CH                = 3
)

(
    input                               reset_n,
    input                               clk_i,
    input [7:0]                         npr_dest_id_i,
    input [7:0]                         cmpl_dest_id_i,
    input [7:0]                         pr_dest_id_i,
    input                               local_crdts_avail_req_i,
    input [CRDT_CNTR_WIDTH-1:0]         init_local_crdts_npr_i,
    input [CRDT_CNTR_WIDTH-1:0]         init_local_crdts_cmpl_i,
    input [CRDT_CNTR_WIDTH-1:0]         init_local_crdts_pr_i,
    input [CRDT_CNTR_WIDTH-1:0]         curr_npr_crdts_i,      // u2c flow - how many credits the data occupies
    input [CRDT_CNTR_WIDTH-1:0]         curr_cmpl_crdts_i,
    input [CRDT_CNTR_WIDTH-1:0]         curr_pr_crdts_i,
    output logic [CRDT_CNTR_WIDTH-1:0]  local_crdts_avail_npr_o,
    output logic [CRDT_CNTR_WIDTH-1:0]  local_crdts_avail_cmpl_o,
    output logic [CRDT_CNTR_WIDTH-1:0]  local_crdts_avail_pr_o,
    output logic                        local_crdts_avail_pr_vld_o,
    output logic                        local_crdts_avail_npr_vld_o,
    output logic                        local_crdts_avail_cmpl_vld_o,
    cdx5n_csi_local_crdt_if.s           local_crdt_in,
    cdx5n_csi_snk_sched_ser_ing_if.m    dest_crdt,
    input logic                         initiate_pr_req_i,
    input logic                         initiate_npr_req_i,
    input logic                         initiate_cmpl_req_i,
    input logic                         curr_pr_crdts_vld_i,
    input logic                         curr_npr_crdts_vld_i,
    input logic                         curr_cmpl_crdts_vld_i,
    ///from request_generation 
    input  logic                        req_gen_eop_i,         //internal EOP
    
    input logic                         ld_init_local_pr_credits_i,
    input logic                         ld_init_local_npr_credits_i,
    input logic                         ld_init_local_cmpl_credits_i,
    input  logic                        dest_crdt_vld_i,
    input  logic [NUM_CH-1:0] [DEST_CRDT_WIDTH-1:0]  dest_in_crdt_i,

    input  logic                        type1_in_crdt_vld_i,
    input  logic [10:0]                 type1_in_crdt_i,
    
    output logic [31:0]                 dest_crdts_released_npr_o, 
    output logic [31:0]                 dest_crdts_released_cmpl_o,
    output logic [31:0]                 dest_crdts_released_pr_o
);



localparam [1:0] IDLE = 2'd0, S1= 2'd1, S2=2'd2, S3=2'd3;



//Declarations

logic [2:0] flow_type;
logic [1:0] state;
logic [3:0] count;

logic [NUM_CH-1:0] [TYPE0_CNTR_WIDTH-1:0] dest_crdt_cnt;
logic [NUM_CH-1:0] [TYPE0_CNTR_WIDTH-1:0] dest_crdt_cnt_nxt;
logic [NUM_CH-1:0] dest_crdt_vld;
logic [NUM_CH-1:0] [7:0] dest_id;

logic [TYPE0_CNTR_WIDTH-1:0] dest_crdt_cnt_pr;
logic [TYPE0_CNTR_WIDTH-1:0] dest_crdt_cnt_pr_nxt;

logic [TYPE0_CNTR_WIDTH-1:0] dest_crdt_cnt_npr;
logic [TYPE0_CNTR_WIDTH-1:0] dest_crdt_cnt_npr_nxt;

logic [TYPE0_CNTR_WIDTH-1:0] dest_crdt_cnt_cmpl;
logic [TYPE0_CNTR_WIDTH-1:0] dest_crdt_cnt_cmpl_nxt;


logic curr_pr_crdts_vld_s1;
logic curr_npr_crdts_vld_s1;
logic curr_cmpl_crdts_vld_s1;

logic [10:0] type1_crdt_cnt;
logic [10:0] type1_crdt_cnt_nxt;

ks_sched_msg_t dest_crdt_info;

typedef struct packed {
    logic [1:0] sink_id;
    logic [DST_FIFO_ID_WIDTH-1:0] dst_fifo_id;
    logic [CRDT_CNTR_WIDTH-1:0] cnt;
} src_crdt_t;


src_crdt_t npr_crdt_cntr, npr_crdt_cntr_nxt;
src_crdt_t pr_crdt_cntr, pr_crdt_cntr_nxt;
src_crdt_t cmpl_crdt_cntr, cmpl_crdt_cntr_nxt;


logic inc_npr_crdt, dec_npr_crdt;
logic inc_npr_crdt_s1;
logic inc_pr_crdt_s1,inc_cmpl_crdt_s1;
logic inc_pr_crdt, dec_pr_crdt;
logic inc_cmpl_crdt, dec_cmpl_crdt;
logic pr_cmpl_crdt_en;
logic incr_cmpl_credit_actual_s1, incr_cmpl_credit_actual;
logic incr_pr_credit_actual_s1, incr_pr_credit_actual;

wire inc_pr_crdt_next;
wire inc_cmpl_crdt_next;

logic       reset_done;
logic       reset_done_s1;
logic       reset_done_pulse;

logic [1:0]  csi_local_crdt_snk_id_ff;
csi_flow_t   csi_local_crdt_flow_type_ff;
logic [6:0]  csi_local_crdt_buf_id_ff;
logic [15:0] csi_local_crdt_data_ff;
logic        csi_local_crdt_vld_ff;


logic                                   clr_delay_cnt;
logic [DELAY_CNTR_WIDTH-1:0]            delay_cnt;
logic [DELAY_CNTR_WIDTH-1:0]            delay_cnt_nxt;
logic                                   delay_cnt_rollover;
logic [NUM_CH-1:0] dec_crdt;
logic dec_crdt_npr;
logic dec_crdt_cmpl;
logic npr_sent, cmpl_sent, pr_sent, send_pr;
logic ld_snapshot;
logic npr_set, cmpl_set, pr_set;
logic npr_set_reg, cmpl_set_reg, pr_set_reg;
logic dest_crdt_info_vld, dest_crdt_info_vld_s1;


logic [TYPE0_CNTR_WIDTH-1:0] snapshot_type0_crdt_cnt, snapshot_crdt_cnt, snapshot_cmpl_crdt_cnt, snapshot_npr_crdt_cnt;
logic [10:0] snapshot_type1_crdt_cnt;


`XSRREG_AXIMM(clk_i, reset_n, npr_crdt_cntr, npr_crdt_cntr_nxt, '0)
`XSRREG_AXIMM(clk_i, reset_n, pr_crdt_cntr, pr_crdt_cntr_nxt, '0)
`XSRREG_AXIMM(clk_i, reset_n, cmpl_crdt_cntr, cmpl_crdt_cntr_nxt, '0)

`XSRREG_AXIMM(clk_i, reset_n, curr_pr_crdts_vld_s1, curr_pr_crdts_vld_i, '0)
`XSRREG_AXIMM(clk_i, reset_n, curr_npr_crdts_vld_s1, curr_npr_crdts_vld_i, '0)
`XSRREG_AXIMM(clk_i, reset_n, curr_cmpl_crdts_vld_s1, curr_cmpl_crdts_vld_i, '0)
`XSRREG_AXIMM(clk_i, reset_n, inc_npr_crdt_s1, (inc_npr_crdt & (npr_crdt_cntr < 'd2)), '0)


`XSRREG_AXIMM(clk_i, reset_n, cmpl_set_reg, cmpl_set, '0)
`XSRREG_AXIMM(clk_i, reset_n, pr_set_reg, pr_set, '0)
`XSRREG_AXIMM(clk_i, reset_n, npr_set_reg, npr_set, '0)

//Local credit i/f cannot be backpressured
assign local_crdt_in.local_crdt_rdy = 1'b1;
assign dest_id = {pr_dest_id_i, cmpl_dest_id_i, npr_dest_id_i};

//Input register stage for the local credit interface
`XSRREG_AXIMM(clk_i, reset_n, csi_local_crdt_vld_ff,    local_crdt_in.local_crdt_vld, '0)
`XSRREG_AXIMM(clk_i, reset_n, csi_local_crdt_snk_id_ff, local_crdt_in.local_crdt_snk_id, '0)
`XSRREG_AXIMM(clk_i, reset_n, csi_local_crdt_flow_type_ff, csi_flow_t'(local_crdt_in.local_crdt_flow_type), CSI_NPR)
`XSRREG_AXIMM(clk_i, reset_n, csi_local_crdt_buf_id_ff, local_crdt_in.local_crdt_buf_id, '0)
`XSRREG_AXIMM(clk_i, reset_n, csi_local_crdt_data_ff,   local_crdt_in.local_crdt, '0)



//Generate a pulse after the reset is de-asserted
//This is used to initialize the credit counters from CSR values after reset
`XSRREG_AXIMM(clk_i, reset_n, reset_done, 1'b1, 1'b0)
`XSRREG_AXIMM(clk_i, reset_n, reset_done_s1, reset_done, 1'b0)

assign reset_done_pulse = reset_done & ~reset_done_s1;


always_comb begin

        local_crdts_avail_npr_o   =   npr_crdt_cntr;
        local_crdts_avail_cmpl_o  =   cmpl_crdt_cntr;
        local_crdts_avail_pr_o    =   pr_crdt_cntr;
        
        //local_crdts_avail_pr_vld_o   = (initiate_pr_req_i | inc_pr_crdt | curr_pr_crdts_vld_s1) ? 1'b1 : 1'b0;
        local_crdts_avail_pr_vld_o   = (initiate_pr_req_i | inc_pr_crdt_s1 | curr_pr_crdts_vld_s1) ? 1'b1 : 1'b0;
        //local_crdts_avail_npr_vld_o  = (initiate_npr_req_i | inc_npr_crdt | curr_npr_crdts_vld_s1) ? 1'b1 : 1'b0;
        local_crdts_avail_npr_vld_o  = (initiate_npr_req_i | inc_npr_crdt_s1 | curr_npr_crdts_vld_s1) ? 1'b1 : 1'b0;
        //local_crdts_avail_cmpl_vld_o = (initiate_cmpl_req_i | inc_cmpl_crdt | curr_cmpl_crdts_vld_s1) ? 1'b1 : 1'b0;
        local_crdts_avail_cmpl_vld_o = (initiate_cmpl_req_i | inc_cmpl_crdt_s1 | curr_cmpl_crdts_vld_s1) ? 1'b1 : 1'b0;
        
end

always @(posedge clk_i)
begin
    if(reset_n == 1'b0)
    begin
        pr_cmpl_crdt_en <= 'b1;
    end
    else
    begin
        if(req_gen_eop_i == 1'b1)
            pr_cmpl_crdt_en <=  1'b0;
        else if (dec_pr_crdt || dec_cmpl_crdt)
            pr_cmpl_crdt_en <=  1'b1;
    end    
end

assign  inc_pr_crdt_next   = (pr_cmpl_crdt_en & (!req_gen_eop_i)) ? inc_pr_crdt : 1'b0;
assign  inc_cmpl_crdt_next = (pr_cmpl_crdt_en & (!req_gen_eop_i)) ? inc_cmpl_crdt : 1'b0;

`XSRREG_AXIMM(clk_i, reset_n, inc_pr_crdt_s1, inc_pr_crdt_next, '0 )
`XSRREG_AXIMM(clk_i, reset_n, inc_cmpl_crdt_s1, inc_cmpl_crdt_next, '0 )

/*always_comb begin

    if(req_gen_eop_i == 1'b1)
        pr_cmpl_crdt_en =  1'b0;
    else if (dec_pr_crdt || dec_cmpl_crdt)
        pr_cmpl_crdt_en =  1'b1;   
    else    
        pr_cmpl_crdt_en = pr_cmpl_crdt_en_s1;
end



`XSRREG_AXIMM(clk_i, reset_n, pr_cmpl_crdt_en_s1, pr_cmpl_crdt_en  , '0)
*/

//--------------------------------------------
// Generate incr/decr credit counter updates
//--------------------------------------------
//A credit counter is incremented (by the received credit value) when a credit is received 
//on the local credit interface for its sink ID/buffer ID
//A credit counter is decremented by the no.of credits received from request_gen module when a capsule is sent

//For NPR credit counters
always_comb begin
        inc_npr_crdt = csi_local_crdt_vld_ff & (csi_local_crdt_flow_type_ff == CSI_NPR);
        dec_npr_crdt = curr_npr_crdts_vld_i; //u2c_dat_vld_i & (u2c_dat_flwtyp_i == CSI_NPR);
end

//For CMPL credit counters
always_comb begin
        inc_cmpl_crdt = csi_local_crdt_vld_ff & (csi_local_crdt_flow_type_ff == CSI_CMPT);
        dec_cmpl_crdt = curr_cmpl_crdts_vld_i; //u2c_dat_vld_i & (u2c_dat_flwtyp_i == CSI_CMPT);
end

//For PR credit counters
always_comb begin
        inc_pr_crdt = csi_local_crdt_vld_ff & (csi_local_crdt_flow_type_ff == CSI_PR);
        dec_pr_crdt = curr_pr_crdts_vld_i; //u2c_dat_vld_i & (u2c_dat_flwtyp_i == CSI_PR);
end




//Update NPR credit counters
//Incr by credit value received
//Decr by 1 segment
//For single VC
always_comb begin
        //Static values of assigned buffer IDs that get latched after reset
        npr_crdt_cntr_nxt.dst_fifo_id = 'b0; //cfg_npr_dst_fifo_id;
        npr_crdt_cntr_nxt.sink_id = 'b0; //cfg_npr_dst_fifo_sink_id;

        //default
        npr_crdt_cntr_nxt.cnt = npr_crdt_cntr.cnt;

        if (reset_done_pulse | ld_init_local_npr_credits_i) begin // | ld_npr_dst_fifo_init_crdt) begin
            npr_crdt_cntr_nxt.cnt = init_local_crdts_npr_i; // intial credits configured from microblaze
        end
        else begin
            case ({inc_npr_crdt, dec_npr_crdt})
                2'b10: begin
                    npr_crdt_cntr_nxt.cnt = npr_crdt_cntr.cnt + csi_local_crdt_data_ff[CRDT_CNTR_WIDTH-1:0];
                end

                2'b01: begin
                    npr_crdt_cntr_nxt.cnt = npr_crdt_cntr.cnt - curr_npr_crdts_i;
                end

                2'b11: begin
                    npr_crdt_cntr_nxt.cnt = npr_crdt_cntr.cnt + csi_local_crdt_data_ff[CRDT_CNTR_WIDTH-1:0] - curr_npr_crdts_i;
                end

                default: begin
                    npr_crdt_cntr_nxt.cnt = npr_crdt_cntr.cnt;
                end
            endcase
        end
end

/*
//For multiple VCs
always_comb begin
    for (int i=0; i<NUM_NPR_DST_FIFO; i++) begin
        //Static values of assigned buffer IDs that get latched after reset
        npr_crdt_cntr_nxt[i].dst_fifo_id = cfg_npr_dst_fifo_id[i];
        npr_crdt_cntr_nxt[i].sink_id = cfg_npr_dst_fifo_sink_id[i];

        //default
        npr_crdt_cntr_nxt[i].cnt = npr_crdt_cntr[i].cnt;

        if (reset_done_pulse | ld_npr_dst_fifo_init_crdt[i]) begin
            npr_crdt_cntr_nxt[i].cnt = cfg_npr_dst_fifo_init_crdt[i];
        end
        else begin
            case ({inc_npr_crdt[i], dec_npr_crdt[i]})
                2'b10: begin
                    npr_crdt_cntr_nxt[i].cnt = npr_crdt_cntr[i].cnt + csi_local_crdt_data_ff[CRDT_CNTR_WIDTH-1:0];
                end

                2'b01: begin
                    npr_crdt_cntr_nxt[i].cnt = npr_crdt_cntr[i].cnt - 1;
                end

                2'b11: begin
                    npr_crdt_cntr_nxt[i].cnt = npr_crdt_cntr[i].cnt + csi_local_crdt_data_ff[CRDT_CNTR_WIDTH-1:0] - 1;
                end

                default: begin
                    npr_crdt_cntr_nxt[i].cnt = npr_crdt_cntr[i].cnt;
                end
            endcase
        end
    end
end

*/



//Update PR credit counters
//Incr by credit value received CSI
//Decr by credit value received from request_gen module 
always_comb begin
        //Static values of assigned buffer IDs that get latched after reset
        pr_crdt_cntr_nxt.dst_fifo_id = 'b0; //cfg_pr_dst_fifo_id;
        pr_crdt_cntr_nxt.sink_id = 'b0; //cfg_pr_dst_fifo_sink_id;

        //default
        pr_crdt_cntr_nxt.cnt = pr_crdt_cntr.cnt;

        if (reset_done_pulse | ld_init_local_pr_credits_i) begin
            pr_crdt_cntr_nxt.cnt = init_local_crdts_pr_i; // intial credits configured from microblaze
        end
        else begin
            case ({inc_pr_crdt, dec_pr_crdt})
                2'b10: begin
                    pr_crdt_cntr_nxt.cnt = pr_crdt_cntr.cnt + csi_local_crdt_data_ff[CRDT_CNTR_WIDTH-1:0];
                end

                2'b01: begin
                    pr_crdt_cntr_nxt.cnt = pr_crdt_cntr.cnt - curr_pr_crdts_i;
                end

                2'b11: begin
                    pr_crdt_cntr_nxt.cnt = pr_crdt_cntr.cnt + csi_local_crdt_data_ff[CRDT_CNTR_WIDTH-1:0] 
                                              - curr_pr_crdts_i; 
                end

                default: begin
                    pr_crdt_cntr_nxt.cnt = pr_crdt_cntr.cnt;
                end
            endcase
        end
end

//Update CMPL credit counters
//Incr by credit value received
//Decr by no.of valid segments sent
always_comb begin
        //Static values of assigned buffer IDs that get latched after reset
        //cfg_cmpl_dst_fifo_id gives the base buffer ID and VC ID is added to it to give the actual buffer ID
        cmpl_crdt_cntr_nxt.dst_fifo_id = 'b0; //cfg_cmpl_dst_fifo_id;
        cmpl_crdt_cntr_nxt.sink_id = 'b0; //cfg_cmpl_dst_fifo_sink_id;

        //default
        cmpl_crdt_cntr_nxt.cnt = init_local_crdts_cmpl_i;

        if (reset_done_pulse | ld_init_local_cmpl_credits_i) begin // 
            cmpl_crdt_cntr_nxt.cnt = init_local_crdts_cmpl_i; // intial credits configured from microblaze
        end
        else begin
            case ({inc_cmpl_crdt, dec_cmpl_crdt})
                2'b10: begin
                    cmpl_crdt_cntr_nxt.cnt = cmpl_crdt_cntr.cnt + csi_local_crdt_data_ff[CRDT_CNTR_WIDTH-1:0];
                end

                2'b01: begin
                    cmpl_crdt_cntr_nxt.cnt = cmpl_crdt_cntr.cnt - curr_cmpl_crdts_i ;
                end

                2'b11: begin
                    cmpl_crdt_cntr_nxt.cnt = cmpl_crdt_cntr.cnt + csi_local_crdt_data_ff[CRDT_CNTR_WIDTH-1:0] 
                                                - curr_cmpl_crdts_i; 
                end

                default: begin
                    cmpl_crdt_cntr_nxt.cnt = cmpl_crdt_cntr.cnt;
                end
            endcase
        end
end

/*
// PA : MSG type (mtype) can be BARRIER MSG, SRC_CRED MSG, DEST_CRED, J_ERR MSG, J_RESP MSG, XON_XOFF MSG 

// -------------------------------------------------------------
// Parameters: The encoding of the message types: 
// -------------------------------------------------------------

    localparam SRC_CRED        = 4'b0000;       //  Source credit message
    localparam J_REQ           = 4'b0001;       //  Job Request message
    localparam J_RESP          = 4'b0010;       //  Job Response message
    localparam DEST_CRED       = 4'b0011;       //  Destination credit message ( Applies for both Final and Intermediate destination credit messages ).
    localparam J_ERR           = 4'b0100;       //  Job Error message
    localparam XON_XOFF        = 4'b0101;       //  XON_XOFF message.
    localparam BARRIER         = 4'b1111;       //  Barrier Request or Barrier response
// -------------------------------------------------------------- 
  typedef struct packed {
    logic [3:0]    mtype;
    logic          meop;
    logic          msop;
    logic [15:0]   mdata;
  } ks_sched_msg_t;
*/  

//dest_crdt.msop
//dest_crdt.meop
//dest_crdt.mdata


typedef enum logic {MSG_START=0, MSG_END} msg_sm_e;
msg_sm_e curr_state, next_state;
logic [1:0] curr_state_1; 
logic [1:0] next_state_1;
assign type1_crdt_cnt = 'b0;

`XSRREG_AXIMM(clk_i, reset_n, curr_state, next_state, MSG_START)
`XSRREG_AXIMM(clk_i, reset_n, curr_state_1, next_state_1, S1)


//Take a snapshot of the credit counters of the winner when a winner is picked
`XSRREG_EN_AXIMM(clk_i, reset_n, snapshot_type1_crdt_cnt, type1_crdt_cnt, '0, ld_snapshot)
`XSRREG_EN_AXIMM(clk_i, reset_n, snapshot_crdt_cnt, dest_crdt_cnt[flow_type], '0, ld_snapshot)


//----------------- Type0 credit counters -----------------

//1 credit counter per channel
`XSRREG_AXIMM(clk_i, reset_n, dest_crdt_cnt, dest_crdt_cnt_nxt, '0)
`XSRREG_AXIMM(clk_i, reset_n, dest_crdt_cnt_npr, dest_crdt_cnt_npr_nxt, '0)
`XSRREG_AXIMM(clk_i, reset_n, dest_crdt_cnt_cmpl, dest_crdt_cnt_cmpl_nxt, '0)


assign dest_crdt_vld[0] = (dest_crdt_vld_i & (dest_in_crdt_i[0] != 0) )  ? 1'b1 : 1'b0; //npr
assign dest_crdt_vld[1] = (dest_crdt_vld_i & (dest_in_crdt_i[1] != 0) )  ? 1'b1 : 1'b0; //pr
assign dest_crdt_vld[2] = (dest_crdt_vld_i & (dest_in_crdt_i[2] != 0) )  ? 1'b1 : 1'b0; //cmpl

//Credit counter is incremented when a credit is received
//Credit counter is decremented when a credit msg has been sent
always_comb begin
    dest_crdt_cnt_nxt = dest_crdt_cnt;
    for (int j=0; j<NUM_CH; j++) begin
        case ({dest_crdt_vld[j] , dec_crdt[j]})
            //Increment the counter
            2'b10 : dest_crdt_cnt_nxt[j] = dest_crdt_cnt[j] + dest_in_crdt_i[j];

            //Decrement the counter
            2'b01 : dest_crdt_cnt_nxt[j] = dest_crdt_cnt[j] - snapshot_crdt_cnt;

            //Update the counter
            2'b11 : dest_crdt_cnt_nxt[j] = dest_crdt_cnt[j] + dest_in_crdt_i[j] - snapshot_crdt_cnt;

            default:dest_crdt_cnt_nxt[j] = dest_crdt_cnt[j];
        endcase
    end
end




`XSRREG_AXIMM(clk_i, reset_n, dest_crdt_info_vld_s1, dest_crdt_info_vld , '0)

always_comb begin
    next_state = curr_state;

    dest_crdt_info_vld = 1'b0;
    dec_crdt = '0;
    clr_delay_cnt = 1'b0;
    ld_snapshot = 1'b0;
    dest_crdt_info = '0;
        case (curr_state)
            MSG_START : begin
                if (npr_set | cmpl_set | pr_set) begin
                   dest_crdt_info_vld = 1'b1;
                   dest_crdt_info.msop = 1'b1;
                   dest_crdt_info.meop = 1'b0;
                   dest_crdt_info.mtype = 4'b0011;
                   dest_crdt_info.mdata = {type1_crdt_cnt[7:0], dest_id[flow_type]};   
                   dec_crdt[flow_type] = 1'b0;
                   clr_delay_cnt = 1'b0;
                   ld_snapshot = 1'b1;
                   if (dest_crdt.ser_ing_intf_rdy) 
                     next_state = MSG_END;
		   else
		     next_state = MSG_START;
		end
		else
		begin
                  dest_crdt_info_vld = 1'b0;
                  dest_crdt_info.msop = 1'b0;
                  dest_crdt_info.meop = 1'b0;
                  dest_crdt_info.mtype = 4'b0011;
                  dest_crdt_info.mdata = {type1_crdt_cnt[7:0], dest_id[flow_type]};   
                  dec_crdt[flow_type] = 1'b0;
                  clr_delay_cnt = 1'b0;
                  ld_snapshot = 1'b0;
                  next_state = MSG_START;
		end
                //if (dest_crdt.ser_ing_intf_rdy) 
                //begin
                //  if (npr_set | cmpl_set | pr_set) begin
                //      dest_crdt_info_vld = 1'b1;
                //      dest_crdt_info.msop = 1'b1;
                //      dest_crdt_info.meop = 1'b0;
                //      dest_crdt_info.mtype = 4'b0011;
                //      dest_crdt_info.mdata = {type1_crdt_cnt[7:0], dest_id[flow_type]};   
                //      dec_crdt[flow_type] = 1'b0;
                //      clr_delay_cnt = 1'b0;
                //      ld_snapshot = 1'b1;
                //      next_state = MSG_END;
                //  end
		//  else
		//  begin
                //      dest_crdt_info_vld = 1'b0;
                //      dest_crdt_info.msop = 1'b0;
                //      dest_crdt_info.meop = 1'b0;
                //      dest_crdt_info.mtype = 4'b0011;
                //      dest_crdt_info.mdata = {type1_crdt_cnt[7:0], dest_id[flow_type]};   
                //      dec_crdt[flow_type] = 1'b0;
                //      clr_delay_cnt = 1'b0;
                //      ld_snapshot = 1'b0;
                //      next_state = MSG_START;
		//  end
                //end
                //else
                //begin
                //  dest_crdt_info_vld = 1'b0;
                //  dest_crdt_info.msop = 1'b0;
                //  dest_crdt_info.meop = 1'b0;
                //  dest_crdt_info.mtype = 4'b0011;
                //  dest_crdt_info.mdata = {type1_crdt_cnt[7:0], dest_id[flow_type]};   
                //  dec_crdt[flow_type] = 1'b0;
                //  clr_delay_cnt = 1'b0;
                //  ld_snapshot = 1'b0;
                //  next_state = MSG_START;
                //end
            end

            MSG_END : begin
                    dest_crdt_info_vld = 1'b1;
                    dest_crdt_info.msop = 1'b0;
                    dest_crdt_info.meop = 1'b1;
                    dest_crdt_info.mtype = 4'b0011;
                    //Switch to the snapshot-ed credit cntr values in cycle 2 since the cntr values can 
                    //potentially change between cycles 1 and 2
                    dest_crdt_info.mdata = {snapshot_type1_crdt_cnt[10:8], snapshot_crdt_cnt};
                    ld_snapshot = 1'b0;
                    if (dest_crdt.ser_ing_intf_rdy) begin
                      dec_crdt[flow_type] = 1'b1;
                      clr_delay_cnt = 1'b1;
                      next_state = MSG_START;
                    end 
                    else begin
                      dec_crdt[flow_type] = 1'b0;
                      clr_delay_cnt = 1'b0;
                      next_state = MSG_END;
                    end
            end
        endcase
end

//assign dest_crdt.ser_ing_intf_vld = dest_crdt_info_vld | dest_crdt_info_vld_s1;
assign dest_crdt.ser_ing_intf_vld = dest_crdt_info_vld;
assign dest_crdt.ser_ing_intf_in  = dest_crdt_info;

always @ (posedge clk_i) begin
    if(!reset_n)
    begin
        dest_crdts_released_npr_o <= 'd0;
        dest_crdts_released_cmpl_o <= 'd0;
        dest_crdts_released_pr_o <= 'd0; 
    end
    else if (clr_delay_cnt & (flow_type == 2'd0))
        dest_crdts_released_npr_o <= dest_crdts_released_npr_o + snapshot_crdt_cnt;
    else if (clr_delay_cnt & (flow_type == 2'd1))
        dest_crdts_released_cmpl_o <= dest_crdts_released_cmpl_o + snapshot_crdt_cnt;
    else if (clr_delay_cnt & (flow_type == 2'd2))
        dest_crdts_released_pr_o <= dest_crdts_released_pr_o + snapshot_crdt_cnt;
    else begin
        dest_crdts_released_npr_o <= dest_crdts_released_npr_o;
        dest_crdts_released_cmpl_o <= dest_crdts_released_cmpl_o;
        dest_crdts_released_pr_o <= dest_crdts_released_pr_o;   
    end
end

//arbitration logic for destination credits
always_comb begin

            case(curr_state_1)
            S1: begin
                    if (npr_set_reg == 'b1)  begin 
                        npr_set = 'b1;
                        cmpl_set = 'b0;
                        pr_set = 'b0;
                        flow_type  = 'd0;
                        if(dest_crdt_cnt[0]!='d0) begin
                            flow_type  = 'd0;
                            next_state_1 = S1;
                        end
                        else
                            next_state_1 = S2;
                    end
                    else if (cmpl_set_reg == 'b1) begin
                        cmpl_set = 'b1;
                        npr_set = 'b0;
                        pr_set = 'b0;
                        flow_type = 'd1;
                        if(dest_crdt_cnt[1]!='d0) begin
                            flow_type  = 'd1;
                            next_state_1 = S1;
                        end
                        else
                            next_state_1 = S2;
                    end
                    else if (pr_set_reg == 'b1) begin
                        cmpl_set = 'b0;
                        pr_set = 'b1;
                        npr_set = 'b0;
                        flow_type = 'd2;
                        if(dest_crdt_cnt[2]!='d0) begin
                            flow_type  = 'd2;
                            next_state_1 = S1;
                        end
                        else            
                            next_state_1 = S2;
                    end
                    else 
                      if (dest_crdt_cnt[0] != 0) begin
                        flow_type  = 'd0;
                        npr_set = 'b1;
                        cmpl_set = 'b0;
                        pr_set = 'b0;
                        next_state_1 = S1;
                      end
                      else if (dest_crdt_cnt[1] != 0) begin
                        flow_type  = 'd1;
                        cmpl_set = 'b1;
                        npr_set = 'b0;
                        pr_set = 'b0;
                        next_state_1 = S1;
                      end
                      else if (dest_crdt_cnt[2] != 0) begin
                        flow_type  = 'd2;
                        pr_set = 'b1;
                        cmpl_set = 'b0;
                        npr_set = 'b0;
                        next_state_1 = S1;
                      end                 
                      else begin 
                        npr_set = 'b0;
                        cmpl_set = 'b0;
                        pr_set = 'b0;
                        flow_type  = 'd3;
                        next_state_1  = S2;
                      end
            end
            
            S2: begin
                npr_set = 'b0;
                cmpl_set = 'b0;
                pr_set = 'b0;
                flow_type = 'd3;
                if((dest_crdt_cnt[0]!='d0) | (dest_crdt_cnt[1]!='d0) | (dest_crdt_cnt[2]!='d0))
                    next_state_1 = S1;
                else
                    next_state_1 = S2;
            end
            default: begin 
                    npr_set = 'b0;
                    cmpl_set = 'b0;
                    pr_set = 'b0;
                    //count = 'd0;
                    next_state_1 = S1;
                    flow_type = 'd3;
            end
        endcase
end




endmodule
