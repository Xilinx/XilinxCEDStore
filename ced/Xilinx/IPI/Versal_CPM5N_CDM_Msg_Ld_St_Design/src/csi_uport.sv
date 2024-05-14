//-----------------------------------------------------------------------------
//
// (c) Copyright 1986-2022 Xilinx, Inc. All rights reserved.
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
`timescale 1ns / 1ps
`include "cdx5n_csi_defines.svh"

module csi_uport #(
    parameter TCQ                         = 0,
    parameter USER_PORT_INST              = "PORT0",
    parameter CRDT_CNTR_WIDTH             = 13,
    parameter PR_CONTROL_RAM_WIDTH        = 128,
    parameter PR_DATA_RAM_WIDTH           = 128,
    parameter NPR_CONTROL_RAM_WIDTH       = 128,
    parameter NPR_DATA_RAM_WIDTH          = 128,
    parameter CMPL_CONTROL_RAM_WIDTH      = 256,
    parameter CMPL_DATA_RAM_WIDTH         = 32,
    parameter PR_CONTROL_RAM_ADDR_WIDTH   = 9,
    parameter PR_DATA_RAM_ADDR_WIDTH      = 9,
    parameter NPR_CONTROL_RAM_ADDR_WIDTH  = 9,
    parameter NPR_DATA_RAM_ADDR_WIDTH     = 9,
    parameter CMPL_CONTROL_RAM_ADDR_WIDTH = 9,
    parameter CMPL_DATA_RAM_ADDR_WIDTH    = 9,
    parameter PR_SEED_RAM_ADDR            = 9,
    parameter CMPL_SEED_RAM_ADDR          = 9,
    parameter PR_SEED_WIDTH               = 64,
    parameter CMPL_SEED_WIDTH             = 64,
    parameter CHECKER_FIX_PATTERN         = 1
    )(
    input                             clk, 
    input                             rst_n,
    cdx5n_fab_2s_seg_if.out           f2csi_prcmplout,
    cdx5n_fab_1s_seg_if.out           f2csi_npr_out,
    cdx5n_fab_2s_seg_if.in            csi2f_in,
    cdx5n_csi_local_crdt_if.s         local_crdt_in,
    cdx5n_csi_snk_sched_ser_ing_if.m  dest_crdt,
    input [31:0]S_AXI_UPORT_araddr,
    input [2:0]S_AXI_UPORT_arprot,
    output S_AXI_UPORT_arready,
    input S_AXI_UPORT_arvalid,
    input [31:0]S_AXI_UPORT_awaddr,
    input [2:0]S_AXI_UPORT_awprot,
    output S_AXI_UPORT_awready,
    input S_AXI_UPORT_awvalid,
    input S_AXI_UPORT_bready,
    output [1:0]S_AXI_UPORT_bresp,
    output S_AXI_UPORT_bvalid,
    output [31:0]S_AXI_UPORT_rdata,
    input S_AXI_UPORT_rready,
    output [1:0]S_AXI_UPORT_rresp,
    output S_AXI_UPORT_rvalid,
    input [31:0]S_AXI_UPORT_wdata,
    output S_AXI_UPORT_wready,
    input [3:0]S_AXI_UPORT_wstrb,
    input S_AXI_UPORT_wvalid,
    input s_aximm00_awvalid_i,
    input s_aximm00_wvalid_i,
    input s_aximm00_arvalid_i,
    input s_aximm00_rvalid_i,
    input s_aximm00_wlast_i,
    input s_aximm00_rlast_i,
    input m_aximm00_awvalid_i,
    input m_aximm00_wvalid_i,
    input m_aximm00_arvalid_i,
    input m_aximm00_rvalid_i,
    input m_aximm00_wlast_i,
    input m_aximm00_rlast_i,
    input m_aximm00_arready_i,
    input m_aximm00_awready_i
    );


    cdx5n_fab_2s_seg_if           f2csi_prcmplout_int ();
    cdx5n_fab_1s_seg_if           f2csi_npr_out_int   ();
    wire                     s_axil_awvalid  ;
    wire                     s_axil_awready  ;
    wire                     s_axil_wvalid   ;
    wire                     s_axil_wready   ;
    wire                     s_axil_rvalid   ;
    wire                     s_axil_rready   ;
    wire    [31:0]           s_axil_awaddr   ;
    wire    [31:0]           s_axil_wdata    ;
    wire    [31:0]           s_axil_rdata    ;
    wire                     s_axil_arready  ;
    wire    [31:0]           s_axil_araddr   ;
    wire                     s_axil_arvalid  ;
    wire    [1:0]            s_axil_bresp;
    wire                     s_axil_bvalid;
    wire                     s_axil_bready;
    wire    [1:0]            s_axil_rresp;
    wire    [3:0]            s_axil_wstrb;
    wire    [639:0]          decoded_pr_data;
    wire    [319:0]          decoded_pr_data_p1;
    wire    [639:0]          decoded_cmpl_data;
    wire    [319:0]          decoded_cmpl_data_p1;
    wire    [1:0]            pr_req;
    wire    [1:0]            cmpl_req;
    wire    [8:0]            seg_len; 
    wire                     mb_initialize_pr_done;
    wire    [31:0]           init_value_pr_from_mb_0;
    wire    [31:0]           init_value_pr_from_mb_1;
    wire                     mb_initialize_cmpl_done;
    wire    [31:0]           init_value_cmpl_from_mb_0;
    wire    [31:0]           init_value_cmpl_from_mb_1;
    wire                     c2u_dat_chk_pass;
    wire                     c2u_dat_chk_err;
    wire                     error;
    wire                     c2u_dat_chk_pass_p1;
    wire                     c2u_dat_chk_err_p1;
    wire                     error_p1;
    wire    [1:0]            c2u_dat_chk_dn;
    wire    [1:0]            c2u_dat_chk_st; 
    wire    [1:0]            dat_chk_st_d;  
    wire    [12:0]           pr_crdts;    
    wire    [12:0]           npr_crdts;    
    wire    [12:0]           cmpl_crdts;  
    wire    [12:0]           init_local_crdts_npr;
    wire    [12:0]           init_local_crdts_cmpl;
    wire    [12:0]           init_local_crdts_pr;
    wire    [7:0]            npr_dest_id;
    wire    [7:0]            cmpl_dest_id;
    wire    [7:0]            pr_dest_id;
    wire    [3:0]            c2u_dat_flwtype;
    wire                     dest_crdts_vld;
    wire [5:0] cap_type;
    logic [5:0] req_type;
    wire [7:0] msg_type;
    wire [1:0] addr_type;

    logic                                     initiate_pr_req;
    logic                                     initiate_npr_req;
    logic                                     initiate_cmpl_req;
    logic  [PR_CONTROL_RAM_WIDTH-1:0]         mb_pr_control_data;
    logic  [PR_DATA_RAM_WIDTH-1:0]            mb_pr_data;
    logic  [NPR_CONTROL_RAM_WIDTH-1:0]        mb_npr_control_data;
    logic  [NPR_DATA_RAM_WIDTH-1:0]           mb_npr_data;
    (*mark_debug = "true"*)logic  [CMPL_CONTROL_RAM_WIDTH-1:0]       mb_cmpl_control_data;
    (*mark_debug = "true"*)logic  [CMPL_DATA_RAM_WIDTH-1:0]          mb_cmpl_data;
    //To Microblaze                            
    logic                                    pr_txn_in_process;
    logic                                    npr_txn_in_process;
    logic                                    cmpl_txn_in_proress;
    logic  [PR_CONTROL_RAM_ADDR_WIDTH-1:0]   pr_control_ram_rdaddr;
    logic  [PR_DATA_RAM_ADDR_WIDTH-1:0]      pr_data_ram_rdaddr;
    logic  [NPR_CONTROL_RAM_ADDR_WIDTH-1:0]  npr_control_ram_rdaddr;
    logic  [NPR_DATA_RAM_ADDR_WIDTH-1:0]     npr_data_ram_rdaddr;
    logic  [CMPL_CONTROL_RAM_ADDR_WIDTH-1:0] cmpl_control_ram_rdaddr;
    logic  [CMPL_DATA_RAM_ADDR_WIDTH-1:0]    cmpl_data_ram_rdaddr;
    //Credit Manager IF
    logic  [CRDT_CNTR_WIDTH-1:0]              local_crdts_avail_npr;
    logic  [CRDT_CNTR_WIDTH-1:0]              local_crdts_avail_pr;
    logic  [CRDT_CNTR_WIDTH-1:0]              local_crdts_avail_cmpl;
    (*mark_debug = "true"*)logic                                     local_crdts_avail_npr_vld;
    (*mark_debug = "true"*)logic                                     local_crdts_avail_pr_vld;
    (*mark_debug = "true"*)logic                                     local_crdts_avail_cmpl_vld;    
    //From Decoder                             
    logic                                    npr_requested;                                        
    //To Encoder                               
    logic [319:0]                            enc_pr_data;
    logic [319:0]                            enc_pr_data_s1;
    logic [1:0]                              enc_pr_data_valid;
    logic [319:0]                            enc_npr_data;
    logic                                    enc_npr_data_valid;
    logic [319:0]                            enc_cmpl_data;
    logic [319:0]                            enc_cmpl_data_s1;
    logic [1:0]                              enc_cmpl_data_valid;
    logic                                    enc_sop;
    logic                                    enc_eop;
    logic                                    enc_eop_s1;
    logic                                    enc_npr_sop;
    logic                                    enc_npr_eop;
    csi_capsule_t                            enc_cap_header;
    csi_capsule_t                            enc_npr_cap_header;
    logic [1:0]                              enc_flow_typ;
    logic [2:0]                              credits_used;
    //To Credit Manager
    logic  [12:0]                            pr_local_credits_used;
    logic                                    pr_local_credits_avail;
    logic  [12:0]                            npr_local_credits_used;
    logic                                    npr_local_credits_avail;
    logic  [12:0]                            cmpl_local_credits_used;
    logic                                    cmpl_local_credits_avail;  
    logic                                    ld_init_local_pr_credits;
    logic                                    ld_init_local_npr_credits;
    logic                                    ld_init_local_cmpl_credits;
    //To Request Generator
    logic  [7:0]                             csi_after_pr_seq;
    logic                                    csi_after_pr_seq_valid_o;                                          
    logic                                    pr_control_bram_clk;
    logic                                    pr_data_bram_clk; 
    logic                                    npr_control_bram_clk;
    logic                                    npr_data_bram_clk;
    logic                                    cmpl_control_bram_clk;
    logic                                    cmpl_data_bram_clk;  
    logic                                    npr_control_bram_en;
    logic  [15:0]                            npr_control_bram_we;
    logic  [8:0]                             npr_control_bram_addr;
    logic  [127:0]                           npr_control_bram_wdata;
    logic                                    pr_control_bram_en;
    logic  [15:0]                            pr_control_bram_we;
    logic  [8:0]                             pr_control_bram_addr;
    logic  [127:0]                           pr_control_bram_wdata;    
    logic                                    npr_data_bram_en;
    logic  [15:0]                            npr_data_bram_we;
    logic  [8:0]                             npr_data_bram_addr;
    logic  [127:0]                           npr_data_bram_wdata;
    logic                                    pr_data_bram_en;
    logic  [15:0]                            pr_data_bram_we;
    logic  [8:0]                             pr_data_bram_addr;
    logic  [127:0]                           pr_data_bram_wdata;   
    logic                                    cmpl_control_ram_en;
    logic                                    cmpl_control_ram_we;
    logic  [8:0]                             cmpl_control_ram_waddr;
    logic  [255:0]                           cmpl_control_ram_wdata;
    logic                                    cmpl_data_bram_en;
    logic  [3:0]                             cmpl_data_bram_we;
    logic  [8:0]                             cmpl_data_bram_addr;
    logic  [31:0]                            cmpl_data_bram_wdata;
    logic  [1:0]                             f2csi_prcmpl_rdy;
    logic                                    f2csi_npr_rdy;
    logic  [31:0]                            pr_pass_count;
    logic  [31:0]                            npr_pass_count;
    logic  [31:0]                            cmpl_pass_count;
    logic  [31:0]                            cmpl_err_count;
    logic  [31:0]                            npr_err_count;
    logic  [31:0]                            pr_err_count; 
    logic  [31:0]                            m_aximm00_arvalid_cnt;
    logic  [31:0]                            m_aximm00_awvalid_cnt;
    logic  [31:0]                            m_aximm00_rvalid_cnt;
    logic  [31:0]                            m_aximm00_wvalid_cnt;
    logic  [31:0]                            m_aximm00_rlast_cnt;
    logic  [31:0]                            m_aximm00_wlast_cnt;
    logic  [31:0]                            m_aximm00_awready_cnt;
    logic  [31:0]                            m_aximm00_arready_cnt;
    logic  [31:0]                            s_aximm00_arvalid_cnt;
    logic  [31:0]                            s_aximm00_awvalid_cnt;
    logic  [31:0]                            s_aximm00_rvalid_cnt;
    logic  [31:0]                            s_aximm00_wvalid_cnt;
    logic  [31:0]                            s_aximm00_rlast_cnt;
    logic  [31:0]                            s_aximm00_wlast_cnt;
    logic  [31:0]                            dest_crdts_released_npr;
    logic  [31:0]                            dest_crdts_released_cmpl;
    logic  [31:0]                            dest_crdts_released_pr;     
    logic                                    cmpl_control_ram_data_ready;    
    logic                                    check_p1;
    logic                                    soft_rst;
    logic                                    counter_rst;
    logic  [1:0]                             barrier_cap_detected;
    logic  [1:0]                             iob_ctl_cap_detected;
    wire   [31:0]   addrb_cmpl_data  ;
    wire   [31:0]   addrb_npr_cmd    ;
    wire   [31:0]   addrb_npr_data   ;
    wire   [31:0]   addrb_pr_cmd     ;
    wire   [31:0]   addrb_pr_data    ;
           
    wire   [31:0]   doutb_cmpl_data  ;
    wire   [127:0]  doutb_npr_cmd    ;
    wire   [127:0]  doutb_npr_data   ;
    wire   [127:0]  doutb_pr_cmd     ;
    wire   [127:0]  doutb_pr_data    ;   

//  wire [31:0]   addrb_cmpl_data  ;
//    wire [31:0]   addrb_npr_cmd    ;
//    wire [31:0]   addrb_npr_data   ;
//    wire [31:0]   addrb_pr_cmd     ;
//    wire [31:0]   addrb_pr_data    ;
    
//  wire [31:0]   doutb_cmpl_data  ;
//  wire [127:0]  doutb_npr_cmd    ;
//  wire [127:0]  doutb_npr_data   ;
//  wire [127:0]  doutb_pr_cmd     ;
//  wire [127:0]  doutb_pr_data    ;

    logic [PR_SEED_RAM_ADDR-1:0]   pr_check_seed_ram_raddr;
    logic [PR_SEED_WIDTH-1:0]      mb_pr_check_seed ;
    logic [CMPL_SEED_RAM_ADDR-1:0] cmpl_check_seed_ram_raddr;
    logic [CMPL_SEED_WIDTH-1:0]    mb_cmpl_check_seed ;
    
////////////////////////////////Debug counters //////////////////////////////////////

logic [31:0] pr_data_ram_read_count;
logic [31:0] pr_cmd_ram_read_count;
logic [31:0] npr_data_ram_read_count;
logic [31:0] npr_cmd_ram_read_count;
logic [31:0] cmpl_data_ram_read_count;
logic [31:0] cmpl_cmd_ram_read_count;
logic [31:0] cmpl_seed_ram_count;
logic [31:0] pr_seed_ram_count;

    (*mark_debug = "true"*)logic  [31:0]                             npr_sop_received_cnt;
    (*mark_debug = "true"*)logic  [7:0]                              npr_sop_transrq_received_cnt;
    (*mark_debug = "true"*)logic  [7:0]                              npr_sop_trans_received_cnt;
    (*mark_debug = "true"*)logic  [31:0]                             npr_at_sop_received_cnt;
    (*mark_debug = "true"*)logic  [31:0]                             pr_msg_sop_received_cnt;

    (*mark_debug = "true"*)logic  [31:0]                             cmpl_sop_received_cnt; 
    (*mark_debug = "true"*)logic  [31:0]                             pr_sop_received_cnt;
    (*mark_debug = "true"*)logic  [7:0]                              pr_sop_transrq_received_cnt;
    (*mark_debug = "true"*)logic  [7:0]                              pr_sop_trans_received_cnt;

    (*mark_debug = "true"*)logic  [31:0]                             npr_eop_received_cnt;
    (*mark_debug = "true"*)logic  [31:0]                             cmpl_eop_received_cnt; 
    (*mark_debug = "true"*)logic  [31:0]                             pr_eop_received_cnt;
    (*mark_debug = "true"*)logic  [11:0]                             pr_msg_sspl_sop_received_cnt;
    (*mark_debug = "true"*)logic  [11:0]                             pr_msg_vdm_sop_received_cnt;
    (*mark_debug = "true"*)logic  [15:0]                             pr_msg_ats_invreq_sop_received_cnt;
    (*mark_debug = "true"*)logic  [15:0]                             pr_msg_ats_invcmpl_sop_received_cnt;
    (*mark_debug = "true"*)logic  [15:0]                             pr_msg_ats_pagereq_received_cnt;
    (*mark_debug = "true"*)logic  [15:0]                             pr_msg_ats_prg_resp_received_cnt;

    (*mark_debug = "true"*)logic  [31:0]                             pr_sop_sent_cnt;
    (*mark_debug = "true"*)logic  [31:0]                             cmpl_sop_sent_cnt;
    (*mark_debug = "true"*)logic  [31:0]                             npr_sop_sent_cnt;
    (*mark_debug = "true"*)logic  [31:0]                             npr_at_sop_sent_cnt;
    (*mark_debug = "true"*)logic  [31:0]                             pr_eop_sent_cnt;
    (*mark_debug = "true"*)logic  [31:0]                             cmpl_eop_sent_cnt;
    (*mark_debug = "true"*)logic  [31:0]                             npr_eop_sent_cnt;

    (*mark_debug = "true"*)logic  [31:0]                             npr_ibctl_rxd_cnt;
    (*mark_debug = "true"*)logic  [31:0]                             npr_obctl_rxd_cnt;
    (*mark_debug = "true"*)logic  [31:0]                             cmpl_ibctl_rxd_cnt;
    (*mark_debug = "true"*)logic  [31:0]                             cmpl_obctl_rxd_cnt;
     logic  [7:0]                             msgtype_sts;


logic [9:0]  uport_wr_mem_ram_addr;    
logic [9:0]  uport_rd_mem_ram_addr;    
logic        uport_wr_rd_mem_ram_en;
logic [31:0] uport_wr_rd_mem_ram_wdata;
logic [31:0] uport_wr_rd_mem_ram_rdata;
logic [3:0]  uport_wr_rd_mem_ram_wen;

wire count_rstn;
wire npr_ibctl_detected_seg0;
wire npr_ibctl_detected_seg1;
wire cmpl_ibctl_detected_seg0;
wire cmpl_ibctl_detected_seg1;

wire cmpl_sent_sop_from_uport_seg0;
wire cmpl_sent_sop_from_uport_seg1;
wire cmpl_sent_eop_from_uport_seg0;
wire cmpl_sent_eop_from_uport_seg1;

wire npr_sent_sop_from_uport_seg0;
wire npr_sent_sop_from_uport_seg1;
wire npr_sent_eop_from_uport_seg0;
wire npr_sent_eop_from_uport_seg1;

wire pr_sent_sop_from_uport_seg0;
wire pr_sent_sop_from_uport_seg1;
wire pr_sent_eop_from_uport_seg0;
wire pr_sent_eop_from_uport_seg1;

wire npr_sop_detected_seg0;
wire npr_sop_detected_seg1;
wire npr_eop_detected_seg0;
wire npr_eop_detected_seg1;

wire pr_sop_detected_seg0;
wire pr_sop_detected_seg1;
wire pr_eop_detected_seg0;
wire pr_eop_detected_seg1;

wire cmpl_sop_detected_seg0;
wire cmpl_sop_detected_seg1;
wire cmpl_eop_detected_seg0;
wire cmpl_eop_detected_seg1;

assign npr_ibctl_detected_seg0 = (~csi2f_in.seg[0][7])& (~csi2f_in.seg[0][6]) & (csi2f_in.seg[0][5:0] == 6'h14) & csi2f_in.vld[0] & csi2f_in.rdy[0] & csi2f_in.sop[0] ;
assign npr_ibctl_detected_seg1 = (~csi2f_in.seg[1][7])& (~csi2f_in.seg[1][6]) & (csi2f_in.seg[1][5:0] == 6'h14) & csi2f_in.vld[1] & csi2f_in.rdy[1] & csi2f_in.sop[1] ;
assign npr_obctl_detected_seg0 = (~csi2f_in.seg[0][7])& (~csi2f_in.seg[0][6]) & (csi2f_in.seg[0][5:0] == 6'h15) & csi2f_in.vld[0] & csi2f_in.rdy[0] & csi2f_in.sop[0] ;
assign npr_obctl_detected_seg1 = (~csi2f_in.seg[1][7])& (~csi2f_in.seg[1][6]) & (csi2f_in.seg[1][5:0] == 6'h15) & csi2f_in.vld[1] & csi2f_in.rdy[1] & csi2f_in.sop[1] ;
 

assign cmpl_ibctl_detected_seg0 = (~csi2f_in.seg[0][7])& (csi2f_in.seg[0][6]) & (csi2f_in.seg[0][5:0] == 6'h14) & csi2f_in.vld[0] & csi2f_in.rdy[0] & csi2f_in.sop[0] ;
assign cmpl_ibctl_detected_seg1 = (~csi2f_in.seg[1][7])& (csi2f_in.seg[1][6]) & (csi2f_in.seg[1][5:0] == 6'h14) & csi2f_in.vld[1] & csi2f_in.rdy[1] & csi2f_in.sop[1] ;
assign cmpl_obctl_detected_seg0 = (~csi2f_in.seg[0][7])& (csi2f_in.seg[0][6]) & (csi2f_in.seg[0][5:0] == 6'h15) & csi2f_in.vld[0] & csi2f_in.rdy[0] & csi2f_in.sop[0] ;
assign cmpl_obctl_detected_seg1 = (~csi2f_in.seg[1][7])& (csi2f_in.seg[1][6]) & (csi2f_in.seg[1][5:0] == 6'h15) & csi2f_in.vld[1] & csi2f_in.rdy[1] & csi2f_in.sop[1] ;

 
assign npr_sop_detected_seg0 = (~csi2f_in.seg[0][7])& (~csi2f_in.seg[0][6]) & csi2f_in.vld[0] & csi2f_in.rdy[0] & csi2f_in.sop[0] ;
assign npr_sop_detected_seg1 = (~csi2f_in.seg[1][7])& (~csi2f_in.seg[1][6]) & csi2f_in.vld[1] & csi2f_in.rdy[1] & csi2f_in.sop[1]  ;  
assign cap_type =  csi2f_in.seg[0][5:0];

assign cmpl_sop_detected_seg0 = (~csi2f_in.seg[0][7])& csi2f_in.seg[0][6] & csi2f_in.vld[0] & csi2f_in.rdy[0] & csi2f_in.sop[0] ;
assign cmpl_sop_detected_seg1 = (~csi2f_in.seg[1][7])& csi2f_in.seg[1][6] & csi2f_in.vld[1] & csi2f_in.rdy[1] & csi2f_in.sop[1]  ;

assign pr_sop_detected_seg0 = (csi2f_in.seg[0][7])& (~csi2f_in.seg[0][6]) & csi2f_in.vld[0] & csi2f_in.rdy[0] & csi2f_in.sop[0] ;
assign pr_sop_detected_seg1 = (csi2f_in.seg[1][7])& (~csi2f_in.seg[1][6]) & csi2f_in.vld[1] & csi2f_in.rdy[1] & csi2f_in.sop[1] ; 

assign npr_eop_detected_seg0 = (~csi2f_in.seg[0][7])& (~csi2f_in.seg[0][6]) & csi2f_in.vld[0] & csi2f_in.rdy[0] & csi2f_in.eop[0] ;
assign npr_eop_detected_seg1 = (~csi2f_in.seg[1][7])& (~csi2f_in.seg[1][6]) & csi2f_in.vld[1] & csi2f_in.rdy[1] & csi2f_in.eop[1] ;   

assign cmpl_eop_detected_seg0 = (~csi2f_in.seg[0][7])& csi2f_in.seg[0][6] & csi2f_in.vld[0] & csi2f_in.rdy[0] & csi2f_in.eop[0] ;
assign cmpl_eop_detected_seg1 = (~csi2f_in.seg[1][7])& csi2f_in.seg[1][6] & csi2f_in.vld[1] & csi2f_in.rdy[1] & csi2f_in.eop[1] ; 

assign pr_eop_detected_seg0 = (csi2f_in.seg[0][7])& (~csi2f_in.seg[0][6]) & csi2f_in.vld[0] & csi2f_in.rdy[0] & csi2f_in.eop[0] ;
assign pr_eop_detected_seg1 = (csi2f_in.seg[1][7])& (~csi2f_in.seg[1][6]) & csi2f_in.vld[1] & csi2f_in.rdy[1] & csi2f_in.eop[1] ; 
assign msg_type =  csi2f_in.seg[0][149:142];
assign addr_type =  csi2f_in.seg[0][147:146];

assign npr_sent_sop_from_uport_seg0 = f2csi_npr_out.vld & f2csi_npr_out.rdy & f2csi_npr_out.sop ;


assign npr_sent_eop_from_uport_seg0 = f2csi_npr_out.vld & f2csi_npr_out.rdy & f2csi_npr_out.eop ;
assign req_type =  enc_npr_cap_header.hdr.csi_type[5:0];


assign pr_sent_sop_from_uport_seg0 = (f2csi_prcmplout.seg[0][7])& (~f2csi_prcmplout.seg[0][6]) & f2csi_prcmplout.vld[0] & f2csi_prcmplout.rdy[0] & f2csi_prcmplout.sop[0] ;
assign pr_sent_sop_from_uport_seg1 = (f2csi_prcmplout.seg[1][7])& (~f2csi_prcmplout.seg[1][6]) & f2csi_prcmplout.vld[1] & f2csi_prcmplout.rdy[1] & f2csi_prcmplout.sop[1] ; 

assign pr_sent_eop_from_uport_seg0 = (enc_cap_header.hdr.csi_flow[1:0] ==2) & f2csi_prcmplout.vld[0] & f2csi_prcmplout.rdy[0] & f2csi_prcmplout.eop[0] ;
assign pr_sent_eop_from_uport_seg1 = (enc_cap_header.hdr.csi_flow[1:0] ==2) & f2csi_prcmplout.vld[1] & f2csi_prcmplout.rdy[1] & f2csi_prcmplout.eop[1] ; 


assign cmpl_sent_sop_from_uport_seg0 = (~f2csi_prcmplout.seg[0][7])& (f2csi_prcmplout.seg[0][6]) & f2csi_prcmplout.vld[0] & f2csi_prcmplout.rdy[0] & f2csi_prcmplout.sop[0] ;
assign cmpl_sent_sop_from_uport_seg1 = (~f2csi_prcmplout.seg[1][7])& (f2csi_prcmplout.seg[1][6]) & f2csi_prcmplout.vld[1] & f2csi_prcmplout.rdy[1] & f2csi_prcmplout.sop[1] ; 

assign cmpl_sent_eop_from_uport_seg0 = (enc_cap_header.hdr.csi_flow[1:0] ==1) & f2csi_prcmplout.vld[0] & f2csi_prcmplout.rdy[0] & f2csi_prcmplout.eop[0];
assign cmpl_sent_eop_from_uport_seg1 = (enc_cap_header.hdr.csi_flow[1:0] ==1) & f2csi_prcmplout.vld[1] & f2csi_prcmplout.rdy[1] & f2csi_prcmplout.eop[1]; 

assign count_rstn = rst_n & (~soft_rst);


always @ (posedge clk)
begin
    if(!count_rstn)
        npr_ibctl_rxd_cnt <= 'd0;
    else 
    begin
        if(npr_ibctl_detected_seg0 || npr_ibctl_detected_seg1)
            npr_ibctl_rxd_cnt <= npr_ibctl_rxd_cnt + 'd1;
        else
            npr_ibctl_rxd_cnt <= npr_ibctl_rxd_cnt;
    end     
end

always @ (posedge clk)
begin
    if(!count_rstn)
        npr_obctl_rxd_cnt <= 'd0;
    else 
    begin
        if(npr_obctl_detected_seg0 || npr_obctl_detected_seg1)
            npr_obctl_rxd_cnt <= npr_obctl_rxd_cnt + 'd1;
        else
            npr_obctl_rxd_cnt <= npr_obctl_rxd_cnt;
    end     
end

always @ (posedge clk)
begin
    if(!count_rstn)
        cmpl_ibctl_rxd_cnt <= 'd0;
    else 
    begin
        if(cmpl_ibctl_detected_seg0 || cmpl_ibctl_detected_seg1)
            cmpl_ibctl_rxd_cnt <= cmpl_ibctl_rxd_cnt + 'd1;
        else
            cmpl_ibctl_rxd_cnt <= cmpl_ibctl_rxd_cnt;
    end 
end

always @ (posedge clk)
begin
    if(!count_rstn)
        cmpl_obctl_rxd_cnt <= 'd0;
    else 
    begin
        if(cmpl_obctl_detected_seg0 || cmpl_obctl_detected_seg1)
            cmpl_obctl_rxd_cnt <= cmpl_obctl_rxd_cnt + 'd1;
        else
            cmpl_obctl_rxd_cnt <= cmpl_obctl_rxd_cnt;
    end 
end

always @ (posedge clk)
begin
    if(!count_rstn)
        cmpl_sop_sent_cnt <= 'd0;
    else 
    begin
        if(cmpl_sent_sop_from_uport_seg0 || cmpl_sent_sop_from_uport_seg1)
            cmpl_sop_sent_cnt <= cmpl_sop_sent_cnt + 'd1;
        else
            cmpl_sop_sent_cnt <= cmpl_sop_sent_cnt;
    end 
end

always @ (posedge clk)
begin
    if(!count_rstn) begin
        npr_sop_sent_cnt <= 'd0;
        npr_at_sop_sent_cnt <= 'd0; end
    else 
    begin
        if(npr_sent_sop_from_uport_seg0 && (req_type == 'd0)) 
            npr_sop_sent_cnt <= npr_sop_sent_cnt + 'd1;
        else if (npr_sent_sop_from_uport_seg0 && (req_type == 'h8 || req_type == 'h9 || req_type == 'ha)) 
            npr_at_sop_sent_cnt <= npr_at_sop_sent_cnt + 'd1;
        else 
          begin
            npr_sop_sent_cnt <= npr_sop_sent_cnt;
            npr_at_sop_sent_cnt <= npr_at_sop_sent_cnt;
          end
    end 
end
always @ (posedge clk)
begin
    if(!count_rstn)
        pr_sop_sent_cnt <= 'd0;
    else 
    begin
        if(pr_sent_sop_from_uport_seg0 || pr_sent_sop_from_uport_seg1)
            pr_sop_sent_cnt <= pr_sop_sent_cnt + 'd1;
        else
            pr_sop_sent_cnt <= pr_sop_sent_cnt;
    end 
end


always @ (posedge clk)
begin
    if(!count_rstn)
        cmpl_eop_sent_cnt <= 'd0;
    else 
    begin
        if(cmpl_sent_eop_from_uport_seg0 || cmpl_sent_eop_from_uport_seg1)
            cmpl_eop_sent_cnt <= cmpl_eop_sent_cnt + 'd1;
        else
            cmpl_eop_sent_cnt <= cmpl_eop_sent_cnt;
    end 
end

always @ (posedge clk)
begin
    if(!count_rstn)
        npr_eop_sent_cnt <= 'd0;
    else 
    begin
        if(npr_sent_eop_from_uport_seg0)
            npr_eop_sent_cnt <= npr_eop_sent_cnt + 'd1;
        else
            npr_eop_sent_cnt <= npr_eop_sent_cnt;
    end 
end
always @ (posedge clk)
begin
    if(!count_rstn)
        pr_eop_sent_cnt <= 'd0;
    else 
    begin
        if(pr_sent_eop_from_uport_seg0 || pr_sent_eop_from_uport_seg1)
            pr_eop_sent_cnt <= pr_eop_sent_cnt + 'd1;
        else
            pr_eop_sent_cnt <= pr_eop_sent_cnt;
    end 
end


always @ (posedge clk)
begin
    if(!count_rstn) begin
        pr_sop_transrq_received_cnt <= 'd0;
        pr_sop_trans_received_cnt <= 'd0;
       end
    else if((pr_sop_detected_seg0 || pr_sop_detected_seg1) && addr_type == 2'd1)
        pr_sop_transrq_received_cnt <= pr_sop_transrq_received_cnt + 'd1;
    else if((pr_sop_detected_seg0 || pr_sop_detected_seg1) && addr_type == 2'd2)
        pr_sop_trans_received_cnt <= pr_sop_trans_received_cnt + 'd1;
    else 
       begin  
         pr_sop_transrq_received_cnt <= pr_sop_transrq_received_cnt;
         pr_sop_trans_received_cnt <= pr_sop_trans_received_cnt;
       end
end 

always @ (posedge clk)
begin
    if(!count_rstn)
        cmpl_sop_received_cnt <= 'd0;
    else 
    begin
        if(cmpl_sop_detected_seg0 || cmpl_sop_detected_seg1)
            cmpl_sop_received_cnt <= cmpl_sop_received_cnt + 'd1;
        else
            cmpl_sop_received_cnt <= cmpl_sop_received_cnt;
    end 
end

always @ (posedge clk)
begin
    if(!count_rstn) begin
        npr_sop_received_cnt <= 'd0;
        npr_at_sop_received_cnt <= 'd0;
       end
    else if(npr_sop_detected_seg0 || npr_sop_detected_seg1) 
       case(cap_type)
          'h0: npr_sop_received_cnt <= npr_sop_received_cnt + 'd1;
          'h8,'h9,'ha: npr_at_sop_received_cnt <= npr_at_sop_received_cnt + 'd1;
       endcase
    else
      begin
            npr_sop_received_cnt <= npr_sop_received_cnt;
            npr_at_sop_received_cnt <= npr_at_sop_received_cnt;
      end      
end  


always @ (posedge clk)
begin
    if(!count_rstn) begin
        npr_sop_transrq_received_cnt <= 'd0;
        npr_sop_trans_received_cnt <= 'd0;
       end
    else if((npr_sop_detected_seg0 || npr_sop_detected_seg1) && addr_type == 2'd1)
        npr_sop_transrq_received_cnt <=  npr_sop_transrq_received_cnt + 'd1;  
    else if((npr_sop_detected_seg0 || npr_sop_detected_seg1) && addr_type == 2'd2)
        npr_sop_trans_received_cnt <=  npr_sop_trans_received_cnt + 'd1;      
    else
      begin
            npr_sop_trans_received_cnt <= npr_sop_trans_received_cnt;
            npr_sop_transrq_received_cnt <= npr_sop_transrq_received_cnt;
      end      
end 
 
always @ (posedge clk)
begin
    if(!count_rstn) begin
          msgtype_sts  <= 'd0;
       end
    else
      casez ({msg_type,cap_type[3:0]})
         12'h0?C:  msgtype_sts[0] <= 'b1;
         12'h1?C:  msgtype_sts[1] <= 'b1;
         12'h2?C:  msgtype_sts[2] <= 'b1;
         12'h3?C:  msgtype_sts[3] <= 'b1;
         12'h4?C:  msgtype_sts[4] <= 'b1;
         12'h5?C:  msgtype_sts[5] <= 'b1;
         12'h6?C:  msgtype_sts[6] <= 'b1;
         12'h7?C:  msgtype_sts[7] <= 'b1;
         //default:
      endcase      
end   

always @ (posedge clk)
begin
    if(!count_rstn) begin
        pr_sop_received_cnt <= 'd0;
        pr_msg_sop_received_cnt <= 'd0;
        pr_msg_sspl_sop_received_cnt <= 'd0;
        pr_msg_vdm_sop_received_cnt <= 'd0;
        pr_msg_ats_invreq_sop_received_cnt  <= 'd0;
        pr_msg_ats_invcmpl_sop_received_cnt  <= 'd0;
        pr_msg_ats_pagereq_received_cnt  <= 'd0;
        pr_msg_ats_prg_resp_received_cnt  <= 'd0;
       end
    else if((pr_sop_detected_seg0 || pr_sop_detected_seg1))
          case(cap_type)
          'h4: pr_sop_received_cnt <= pr_sop_received_cnt + 'd1;
          'hc: begin 
                if (msg_type == 8'h7E || msg_type == 8'h7F)
                 pr_msg_vdm_sop_received_cnt <=  pr_msg_vdm_sop_received_cnt + 'd1;
                else if (msg_type == 8'h50)
                 pr_msg_sspl_sop_received_cnt <=  pr_msg_sspl_sop_received_cnt + 'd1;
                else if (msg_type == 8'h01)
                 pr_msg_ats_invreq_sop_received_cnt <=  pr_msg_ats_invreq_sop_received_cnt + 'd1;
                else if (msg_type == 8'h02)
                 pr_msg_ats_invcmpl_sop_received_cnt <=  pr_msg_ats_invcmpl_sop_received_cnt + 'd1;
                else if (msg_type == 8'h04)
                 pr_msg_ats_pagereq_received_cnt <=  pr_msg_ats_pagereq_received_cnt + 'd1;
                else if (msg_type == 8'h05)
                 pr_msg_ats_prg_resp_received_cnt <=  pr_msg_ats_prg_resp_received_cnt + 'd1;
                else
                 pr_msg_sop_received_cnt <= pr_msg_sop_received_cnt + 'd1;
                end
          endcase
    else 
       begin  
         pr_msg_sop_received_cnt <= pr_msg_sop_received_cnt;
         pr_sop_received_cnt <= pr_sop_received_cnt;
         pr_msg_sspl_sop_received_cnt <= pr_msg_sspl_sop_received_cnt;
         pr_msg_vdm_sop_received_cnt <= pr_msg_vdm_sop_received_cnt;
         pr_msg_ats_invreq_sop_received_cnt  <= pr_msg_ats_invreq_sop_received_cnt;
         pr_msg_ats_invcmpl_sop_received_cnt  <= pr_msg_ats_invcmpl_sop_received_cnt;
         pr_msg_ats_pagereq_received_cnt  <= pr_msg_ats_pagereq_received_cnt;
         pr_msg_ats_prg_resp_received_cnt  <= pr_msg_ats_prg_resp_received_cnt;
       end
end        
        
  

always @ (posedge clk)
begin
    if(!count_rstn)
        cmpl_eop_received_cnt <= 'd0;
    else 
    begin
        if(cmpl_eop_detected_seg0 || cmpl_eop_detected_seg1)
            cmpl_eop_received_cnt <= cmpl_eop_received_cnt + 'd1;
        else
            cmpl_eop_received_cnt <= cmpl_eop_received_cnt;
    end 
end

always @ (posedge clk)
begin
    if(!count_rstn)
        npr_eop_received_cnt <= 'd0;
    else 
    begin
        if(npr_eop_detected_seg0 || npr_eop_detected_seg1)
            npr_eop_received_cnt <= npr_eop_received_cnt + 'd1;
        else
            npr_eop_received_cnt <= npr_eop_received_cnt;
    end 
end

always @ (posedge clk)
begin
    if(!count_rstn)
        pr_eop_received_cnt <= 'd0;
    else 
    begin
        if(pr_eop_detected_seg0 || pr_eop_detected_seg1)
            pr_eop_received_cnt <= pr_eop_received_cnt + 'd1;
        else
            pr_eop_received_cnt <= pr_eop_received_cnt;
    end 
end


//////////////////////Debug Counters Ending Ending///////////////////////

    
    //credit manager module
    credit_manager credit_manager_1 
    (
    
      .reset_n                   (rst_n & (~soft_rst)),                                                     
      .clk_i                     (clk),  
      .npr_dest_id_i             ((USER_PORT_INST == "PORT2") ? 8'h8 : 8'h0 ), //npr_dest_id),      
      .cmpl_dest_id_i            ((USER_PORT_INST == "PORT2") ? 8'h9 : 8'h1 ), //cmpl_dest_id),   
      .pr_dest_id_i              ((USER_PORT_INST == "PORT2") ? 8'hA : 8'h2 ), //pr_dest_id),  
      .curr_npr_crdts_i          (npr_local_credits_used),
      .curr_npr_crdts_vld_i      (npr_local_credits_used_vld),
      .curr_pr_crdts_i           (pr_local_credits_used),
      .curr_pr_crdts_vld_i       (pr_local_credits_used_vld),
      .curr_cmpl_crdts_i         (cmpl_local_credits_used),
      .curr_cmpl_crdts_vld_i     (cmpl_local_credits_used_vld),
      .init_local_crdts_npr_i    (init_local_crdts_npr),
      .init_local_crdts_cmpl_i   (init_local_crdts_cmpl),
      .init_local_crdts_pr_i     (init_local_crdts_pr), 
      .local_crdts_avail_npr_o   (local_crdts_avail_npr),
      .local_crdts_avail_cmpl_o  (local_crdts_avail_cmpl),
      .local_crdts_avail_pr_o    (local_crdts_avail_pr),
      .local_crdts_avail_pr_vld_o   (local_crdts_avail_pr_vld),
      .local_crdts_avail_npr_vld_o   (local_crdts_avail_npr_vld),
      .local_crdts_avail_cmpl_vld_o   (local_crdts_avail_cmpl_vld),
      .dest_crdts_released_npr_o    (dest_crdts_released_npr),
      .dest_crdts_released_cmpl_o    (dest_crdts_released_cmpl),
      .dest_crdts_released_pr_o     (dest_crdts_released_pr),

      /////////FROM request generation///////////////////////
      .req_gen_eop_i              (enc_eop | enc_eop_s1),
      //////////////////from MB////////////////////////////////////
      .initiate_npr_req_i          (initiate_npr_req),
      .initiate_pr_req_i           (initiate_pr_req),
      .initiate_cmpl_req_i         (initiate_cmpl_req),
      
      .ld_init_local_pr_credits_i   (ld_init_local_pr_credits),
      .ld_init_local_npr_credits_i  (ld_init_local_npr_credits),
      .ld_init_local_cmpl_credits_i (ld_init_local_cmpl_credits),
      
      .local_crdt_in             (local_crdt_in),              
      .dest_crdt                 (dest_crdt), 
      .dest_crdt_vld_i           (dest_crdts_vld),   
      .dest_in_crdt_i            ({pr_crdts,cmpl_crdts,npr_crdts}),    
      .type1_in_crdt_vld_i       ('b0),
      .type1_in_crdt_i           ('b0)    
    
    );    
    
     //IP register interface module
    csi_uport_axil_reg csi_uport_axil_reg_1
    (
    .axi_aclk     (clk),                  
    .axi_aresetn  (rst_n),               
    .axi_awvalid  (s_axil_awvalid),
    .axi_wvalid   (s_axil_wvalid),             
    .axi_wready   (s_axil_wready),             
    .axi_rvalid   (s_axil_rvalid),      
    .axi_rready   (s_axil_rready),             
    .axi_awaddr   (s_axil_awaddr),
    .axi_awready  (s_axil_awready),
    .axi_arready  (s_axil_arready),      
    .axi_wdata    (s_axil_wdata),       
    .axi_rdata    (s_axil_rdata),
    .axi_araddr   (s_axil_araddr),      
    .axi_arvalid  (s_axil_arvalid),
    
    .axi_bresp   (s_axil_bresp),
    .axi_bvalid  (s_axil_bvalid),
    .axi_bready  (s_axil_bready),
    
    .axi_rresp   (s_axil_rresp),
    .axi_wstrb   (s_axil_wstrb),
    
    .soft_rst_o      (soft_rst),
    .counter_rst_o   (counter_rst),
    .npr_dest_id_o     (npr_dest_id),
    .cmpl_dest_id_o    (cmpl_dest_id),
    .pr_dest_id_o      (pr_dest_id),
    
    .init_local_crdts_npr_o    (init_local_crdts_npr),
    .init_local_crdts_cmpl_o   (init_local_crdts_cmpl),
    .init_local_crdts_pr_o     (init_local_crdts_pr), 
    
    .ld_init_local_pr_credits_o   (ld_init_local_pr_credits),
    .ld_init_local_npr_credits_o  (ld_init_local_npr_credits),
    .ld_init_local_cmpl_credits_o (ld_init_local_cmpl_credits),
      
    .init_value_pr_from_mb_0_o   (init_value_pr_from_mb_0),
    .init_value_pr_from_mb_1_o   (init_value_pr_from_mb_1),
    .mb_initialize_pr_done_o     (mb_initialize_pr_done),
    .init_value_cmpl_from_mb_0_o   (init_value_cmpl_from_mb_0),
    .init_value_cmpl_from_mb_1_o   (init_value_cmpl_from_mb_1),
    .mb_initialize_cmpl_done_o     (mb_initialize_cmpl_done),
    
    .pr_txn_in_process_i         (pr_txn_in_process),
    .npr_txn_in_process_i        (npr_txn_in_process), 
    .cmpl_txn_in_process_i       (cmpl_txn_in_process),
    
    .initiate_npr_req_o          (initiate_npr_req),
    .initiate_pr_req_o           (initiate_pr_req),
    .initiate_cmpl_req_o         (initiate_cmpl_req),
    
    .npr_sop_received_count_i           (npr_sop_received_cnt),
    .npr_at_sop_received_cnt_i           (npr_at_sop_received_cnt),
    .pr_msg_sop_received_cnt_i           (pr_msg_sop_received_cnt),
    
    .cmpl_sop_received_count_i          (cmpl_sop_received_cnt),
    .pr_sop_received_count_i           (pr_sop_received_cnt),
    .pr_msg_sspl_sop_received_cnt_i           (pr_msg_sspl_sop_received_cnt),
    .pr_msg_vdm_sop_received_cnt_i           (pr_msg_vdm_sop_received_cnt),

    .pr_msg_ats_invreq_sop_received_cnt_i (pr_msg_ats_invreq_sop_received_cnt),
    .pr_msg_ats_invcmpl_sop_received_cnt_i (pr_msg_ats_invcmpl_sop_received_cnt),
    .pr_msg_ats_pagereq_received_cnt_i (pr_msg_ats_pagereq_received_cnt),
    .pr_msg_ats_prg_resp_received_cnt_i(pr_msg_ats_prg_resp_received_cnt),

    .npr_sop_transrq_received_cnt_i (npr_sop_transrq_received_cnt),
    .npr_sop_trans_received_cnt_i  (npr_sop_trans_received_cnt),
    .pr_sop_transrq_received_cnt_i  (pr_sop_transrq_received_cnt),
    .pr_sop_trans_received_cnt_i   (pr_sop_trans_received_cnt),
 
    .npr_eop_received_count_i           (npr_eop_received_cnt),
    .cmpl_eop_received_count_i          (cmpl_eop_received_cnt),
    .pr_eop_received_count_i           (pr_eop_received_cnt),
    .npr_ibctl_rxd_cnt_i               (npr_ibctl_rxd_cnt),
    .npr_obctl_rxd_cnt_i               (npr_obctl_rxd_cnt),
    .cmpl_ibctl_rxd_cnt_i               (cmpl_ibctl_rxd_cnt),
    .cmpl_obctl_rxd_cnt_i               (cmpl_obctl_rxd_cnt),
    .npr_sop_sent_cnt_i                 (npr_sop_sent_cnt),
    .npr_at_sop_sent_cnt_i              (npr_at_sop_sent_cnt),
    .npr_eop_sent_cnt_i                 (npr_eop_sent_cnt),
    .cmpl_sop_sent_cnt_i                (cmpl_sop_sent_cnt),
    .cmpl_eop_sent_cnt_i                (cmpl_eop_sent_cnt),
    .pr_sop_sent_cnt_i                  (pr_sop_sent_cnt),
    .pr_eop_sent_cnt_i                  (pr_eop_sent_cnt),
    .cmpl_seed_ram_count_i   (cmpl_seed_ram_count),
    .pr_seed_ram_count_i     (pr_seed_ram_count),

    .cmpl_err_count_i            (cmpl_err_count),
    .cmpl_pass_count_i           (cmpl_pass_count),
    .npr_err_count_i             (npr_err_count),
    .npr_pass_count_i            (npr_pass_count),
    .pr_err_count_i              (pr_err_count),
    .pr_pass_count_i             (pr_pass_count),
    .msgtype_sts_i (msgtype_sts),
    
////////////////////Debug counters from request generation ///////////////          
    .pr_data_ram_read_count_i     (pr_data_ram_read_count),
    .pr_cmd_ram_read_count_i      (pr_cmd_ram_read_count),
    .npr_data_ram_read_count_i    (npr_data_ram_read_count),
    .npr_cmd_ram_read_count_i     (npr_cmd_ram_read_count),
    .cmpl_data_ram_read_count_i   (cmpl_data_ram_read_count),
    .cmpl_cmd_ram_read_count_i    (cmpl_cmd_ram_read_count),
//////////////////////////////////////////////////////////////////////////  
    
    .dest_crdts_released_npr_i    (dest_crdts_released_npr),
    .dest_crdts_released_cmpl_i    (dest_crdts_released_cmpl),
    .dest_crdts_released_pr_i    (dest_crdts_released_pr),
    
    .s_aximm00_arvalid_cnt_i     (s_aximm00_arvalid_cnt),
    .s_aximm00_awvalid_cnt_i     (s_aximm00_awvalid_cnt),
    .s_aximm00_rvalid_cnt_i      (s_aximm00_rvalid_cnt),    
    .s_aximm00_wvalid_cnt_i      (s_aximm00_wvalid_cnt),
    .s_aximm00_rlast_cnt_i       (s_aximm00_rlast_cnt),
    .s_aximm00_wlast_cnt_i       (s_aximm00_wlast_cnt),
     
    .m_aximm00_arvalid_cnt_i     (m_aximm00_arvalid_cnt),
    .m_aximm00_awvalid_cnt_i     (m_aximm00_awvalid_cnt),
    .m_aximm00_rvalid_cnt_i      (m_aximm00_rvalid_cnt),    
    .m_aximm00_wvalid_cnt_i      (m_aximm00_wvalid_cnt),
    .m_aximm00_rlast_cnt_i       (m_aximm00_rlast_cnt),
    .m_aximm00_wlast_cnt_i       (m_aximm00_wlast_cnt),
    .m_aximm00_arready_cnt_i     (m_aximm00_arready_cnt),
    .m_aximm00_awready_cnt_i     (m_aximm00_awready_cnt)
    );

   //Receive module : Rx decoder 
    csi_uport_decode csi_uport_decode_inst 
    (
    
    .clk                           (clk),                    
    .rst_n                         (rst_n& (~soft_rst)),
    .csi2f_port0_i                 (csi2f_in), 
    .pr_data_o                     (decoded_pr_data),
    .pr_data_p1_o                  (decoded_pr_data_p1),
    .cmpl_control_ram_data_o       (cmpl_control_ram_wdata),    
    .cmpl_control_ram_addr_o       (cmpl_control_ram_waddr),    
    .cmpl_control_ram_we_o         (cmpl_control_ram_we),   
    .cmpl_data_o                   (decoded_cmpl_data),
    .cmpl_data_p1_o                (decoded_cmpl_data_p1),
    .pr_req_o                      (pr_req),
    .cmpl_req_o                    (cmpl_req),
    .seg_len_o                     (seg_len),    
    .csi_flow_o                    (c2u_dat_flwtype),
    .crdts_pr_o                    (pr_crdts),
    .crdts_npr_o                   (npr_crdts),
    .crdts_cmpl_o                  (cmpl_crdts),
    .crdts_vld_o                   (dest_crdts_vld),
    .dat_chk_st_o                  (c2u_dat_chk_st),
    .dat_chk_st_d_o                (dat_chk_st_d),
    .dat_chk_dn_o                  (c2u_dat_chk_dn),
    .check_p1_o                    (check_p1),
    .barrier_cap_detected_o        (barrier_cap_detected),
    .iob_ctl_cap_detected_o        (iob_ctl_cap_detected),
    .cmpl_control_ram_data_ready   (cmpl_control_ram_data_ready),
    .uport_wr_mem_ram_addr_o       (uport_wr_mem_ram_addr), 
    .uport_rd_mem_ram_addr_o       (uport_rd_mem_ram_addr), 
    .uport_wr_rd_mem_ram_wdata_o   (uport_wr_rd_mem_ram_wdata),
    .uport_wr_rd_mem_ram_rdata     (uport_wr_rd_mem_ram_rdata),
    .uport_wr_rd_mem_ram_wen_o	   (uport_wr_rd_mem_ram_wen)
    );
     
    //Receive module : checker
    csi_uport_checker #(
    .CHECKER_FIX_PATTERN(CHECKER_FIX_PATTERN)
    ) csi_uport_checker_inst (

        .clk                  (clk),
        .rst_n                (rst_n & (~soft_rst)),
        .pr_data_i            (decoded_pr_data),
        .pr_data_p1_i         (decoded_pr_data_p1),
        .cmpl_data_i          (decoded_cmpl_data),
        .cmpl_data_p1_i       (decoded_cmpl_data_p1),
        .pr_req_i             (pr_req),
        .cmpl_req_i           (cmpl_req),
        .seg_len_i            (seg_len),
        .check_p1_i           (check_p1),
        //.initial_pr_seed_i        (mb_pr_check_seed),
        //.initial_cmpl_seed_i      (mb_cmpl_check_seed),
        .cmpl_check_seed_ram_raddr(cmpl_check_seed_ram_raddr),
        .pr_check_seed_ram_raddr  (pr_check_seed_ram_raddr),
        .dat_chk_st_i         (c2u_dat_chk_st),
        .csi_flow_i               (c2u_dat_flwtype),
        .cmpl_seed_ram_count      (cmpl_seed_ram_count),
        .pr_seed_ram_count        (pr_seed_ram_count),
        .initial_pr_seed_i        (CHECKER_FIX_PATTERN ? {2{init_value_pr_from_mb_0}}  : mb_pr_check_seed),
        .initial_cmpl_seed_i      (CHECKER_FIX_PATTERN ? {2{init_value_cmpl_from_mb_0}}: mb_cmpl_check_seed),
/*
        .initial_pr_seed0_i   (init_value_pr_from_mb_0),
        .initial_pr_seed1_i   (init_value_pr_from_mb_1),
        .initial_cmpl_seed0_i (init_value_cmpl_from_mb_0),
        .initial_cmpl_seed1_i (init_value_cmpl_from_mb_1),
        .dat_chk_st_i         (c2u_dat_chk_st),
        .mb_initialize_pr_i   (mb_initialize_pr_done),
        .mb_initialize_cmpl_i (mb_initialize_cmpl_done),
*/      .barrier_cap_detected_i        (barrier_cap_detected),
        .iob_ctl_cap_detected_i        (iob_ctl_cap_detected),
        .check_pass_p1_o      (c2u_dat_chk_pass_p1),
        .check_err_p1_o       (c2u_dat_chk_err_p1),
        .error_p1_o           (error_p1),
        .check_pass_o         (c2u_dat_chk_pass),
        .check_err_o          (c2u_dat_chk_err),
        .error_o              (error)
    );

uport_counters #(.TCQ(0))
uport_counters_inst
(
    .clk                   (clk),
    .rst_n                 (rst_n & (~counter_rst)),
    .data_chk_pass_i       (c2u_dat_chk_pass),
    .data_chk_err_i        (c2u_dat_chk_err),
    .data_chk_dn_i          (c2u_dat_chk_dn),
    .data_chk_st_i          (c2u_dat_chk_st),
    .data_chk_pass_p1_i      (c2u_dat_chk_pass_p1),
    .data_chk_err_p1_i       (c2u_dat_chk_err_p1),
    .capsule_valid_i       (csi2f_in.vld[0]),
    .capsule_valid_p1_i       (csi2f_in.vld[1]),
    .flow_type_i           (c2u_dat_flwtype[1:0]),
    .flow_type_p1_i           (c2u_dat_flwtype[3:2]),
    .csi_dw_len_i       (csi2f_in.seg[0][19:10]),
    .sop_i              (csi2f_in.sop[0]),
    
    .iob_ctl_cap_detected_i  (iob_ctl_cap_detected),
    .barrier_cap_detected_i  (barrier_cap_detected),
    .cmpl_pass_count_o     (cmpl_pass_count),
    .pr_pass_count_o       (pr_pass_count),
    .npr_pass_count_o      (npr_pass_count),
    .cmpl_err_count_o      (cmpl_err_count),
    .pr_err_count_o        (pr_err_count),
    .npr_err_count_o       (npr_err_count),
    .s_aximm00_awvalid_i   (uport_if_wrapper_1.uport_if_i.smartconnect_0_M04_AXI_AWVALID && uport_if_wrapper_1.uport_if_i.smartconnect_0_M04_AXI_AWREADY), //s_aximm00_awvalid_i)   ,
    .s_aximm00_wvalid_i    (uport_if_wrapper_1.uport_if_i.smartconnect_0_M04_AXI_WVALID && (&uport_if_wrapper_1.uport_if_i.smartconnect_0_M04_AXI_WSTRB)),  //s_aximm00_wvalid_i),
    .s_aximm00_arvalid_i   (uport_if_wrapper_1.uport_if_i.smartconnect_0_M04_AXI_ARVALID && uport_if_wrapper_1.uport_if_i.smartconnect_0_M04_AXI_ARREADY ), //s_aximm00_arvalid_i),
    .s_aximm00_rvalid_i    (uport_if_wrapper_1.uport_if_i.smartconnect_0_M04_AXI_RVALID ),  //s_aximm00_rvalid_i),
    .s_aximm00_wlast_i     (uport_if_wrapper_1.uport_if_i.smartconnect_0_M04_AXI_WLAST ),   //s_aximm00_wlast_i),
    .s_aximm00_rlast_i     (uport_if_wrapper_1.uport_if_i.smartconnect_0_M04_AXI_RLAST ),   //s_aximm00_rlast_i),

    .m_aximm00_awvalid_i   (m_aximm00_awvalid_i),
    .m_aximm00_wvalid_i   (m_aximm00_wvalid_i),
    .m_aximm00_arvalid_i   (m_aximm00_arvalid_i),
    .m_aximm00_rvalid_i    (m_aximm00_rvalid_i),
    .m_aximm00_wlast_i     (m_aximm00_wlast_i),
    .m_aximm00_rlast_i     (m_aximm00_rlast_i),
    .m_aximm00_arready_i   (m_aximm00_arready_i),
    .m_aximm00_awready_i   (m_aximm00_awready_i),
    .s_aximm00_rlast_cnt_o (s_aximm00_rlast_cnt),
    .s_aximm00_wlast_cnt_o (s_aximm00_wlast_cnt),
    .s_aximm00_arvalid_cnt_o (s_aximm00_arvalid_cnt),
    .s_aximm00_awvalid_cnt_o (s_aximm00_awvalid_cnt),
    .s_aximm00_wvalid_cnt_o (s_aximm00_wvalid_cnt),
    .s_aximm00_rvalid_cnt_o (s_aximm00_rvalid_cnt),
    .m_aximm00_rlast_cnt_o (m_aximm00_rlast_cnt),
    .m_aximm00_wlast_cnt_o (m_aximm00_wlast_cnt),
    .m_aximm00_arvalid_cnt_o (m_aximm00_arvalid_cnt),
    .m_aximm00_awvalid_cnt_o (m_aximm00_awvalid_cnt),
    .m_aximm00_wvalid_cnt_o (m_aximm00_wvalid_cnt),
    .m_aximm00_rvalid_cnt_o (m_aximm00_rvalid_cnt),
    .m_aximm00_arready_cnt_o (m_aximm00_arready_cnt),
    .m_aximm00_awready_cnt_o (m_aximm00_awready_cnt)
);
//Transmit module : Request generator    
csi_uport_req_gen    
 #(
    .TCQ                         (TCQ),
    .USER_PORT_INST              (USER_PORT_INST),
    .CRDT_CNTR_WIDTH             (CRDT_CNTR_WIDTH),
    .PR_CONTROL_RAM_WIDTH        (PR_CONTROL_RAM_WIDTH),
    .PR_DATA_RAM_WIDTH           (PR_DATA_RAM_WIDTH),
    .NPR_CONTROL_RAM_WIDTH       (NPR_CONTROL_RAM_WIDTH),
    .NPR_DATA_RAM_WIDTH          (NPR_DATA_RAM_WIDTH),
    .CMPL_CONTROL_RAM_WIDTH      (CMPL_CONTROL_RAM_WIDTH),
    .CMPL_DATA_RAM_WIDTH         (CMPL_DATA_RAM_WIDTH),
    .PR_CONTROL_RAM_ADDR_WIDTH   (PR_CONTROL_RAM_ADDR_WIDTH),
    .PR_DATA_RAM_ADDR_WIDTH      (PR_DATA_RAM_ADDR_WIDTH),
    .NPR_CONTROL_RAM_ADDR_WIDTH  (NPR_CONTROL_RAM_ADDR_WIDTH),
    .NPR_DATA_RAM_ADDR_WIDTH     (NPR_DATA_RAM_ADDR_WIDTH),
    .CMPL_CONTROL_RAM_ADDR_WIDTH (CMPL_CONTROL_RAM_ADDR_WIDTH),
    .CMPL_DATA_RAM_ADDR_WIDTH    (CMPL_DATA_RAM_ADDR_WIDTH)
    ) csi_uport_req_gen_inst (
    // Clocks / Resets
    .clk                        (clk),
    .rst_n                      ((rst_n & (~soft_rst))),  
    //From MicroBlaze
    .initiate_pr_req_i          (initiate_pr_req),
    .initiate_npr_req_i         (initiate_npr_req),
    .initiate_cmpl_req_i        (initiate_cmpl_req),
    //From Ram IF
    .mb_pr_control_data_i       (mb_pr_control_data),
    .mb_pr_data_i               (mb_pr_data),
    .mb_npr_control_data_i      (mb_npr_control_data),
    .mb_npr_data_i              (mb_npr_data),
    .mb_cmpl_control_data_i     (mb_cmpl_control_data),
    .mb_cmpl_data_i             (uport_wr_rd_mem_ram_rdata), //mb_cmpl_data),
    //From Decoder 
    .cmpl_control_ram_ready_i   (cmpl_control_ram_data_ready),

    //To Microblaze                            
    .pr_txn_in_process_o        (pr_txn_in_process),
    .npr_txn_in_process_o       (npr_txn_in_process),
    .cmpl_txn_in_process_o      (cmpl_txn_in_process),
    //To Ram IF
    .pr_control_ram_rdaddr_o    (pr_control_ram_rdaddr),
    .pr_data_ram_rdaddr_o       (pr_data_ram_rdaddr),
    .npr_control_ram_rdaddr_o   (npr_control_ram_rdaddr),
    .npr_data_ram_rdaddr_o      (npr_data_ram_rdaddr),
    .cmpl_control_ram_rdaddr_o  (cmpl_control_ram_rdaddr),
    .cmpl_data_ram_rdaddr_o     (cmpl_data_ram_rdaddr),
    
    //Credit Manager IF
    .local_crdts_avail_npr_i      (local_crdts_avail_npr),
    .local_crdts_avail_pr_i       (local_crdts_avail_pr),
    .local_crdts_avail_cmpl_i     (local_crdts_avail_cmpl),
    .local_crdts_avail_npr_vld_i  (local_crdts_avail_npr_vld),
    .local_crdts_avail_pr_vld_i   (local_crdts_avail_pr_vld),
    .local_crdts_avail_cmpl_vld_i (local_crdts_avail_cmpl_vld),
                                               
    //From Decoder                             
    .npr_requested_i            (npr_requested),
                                               
    //To Encoder                               
    .pr_data_o                  (enc_pr_data),
    .pr_data_s1_o               (enc_pr_data_s1),
    .pr_data_valid_o            (enc_pr_data_valid),
    .cmpl_data_o                (enc_cmpl_data),
    .cmpl_data_s1_o             (enc_cmpl_data_s1),
    .cmpl_data_valid_o          (enc_cmpl_data_valid),
    .sop_o                      (enc_sop),
    .eop_o                      (enc_eop),
    .eop_s1_o                   (enc_eop_s1),
    .npr_sop_o                  (enc_npr_sop),
    .npr_eop_o                  (enc_npr_eop),
    .cap_header_o               (enc_cap_header),
    .npr_cap_header_o           (enc_npr_cap_header),
    .flow_typ_o                 (enc_flow_typ),
    .credits_used_o             (credits_used),
    
///////////////////////Inserting Debug Counters/////////////////        
    .pr_data_ram_read_count     (pr_data_ram_read_count),
    .pr_cmd_ram_read_count      (pr_cmd_ram_read_count),
    .npr_data_ram_read_count    (npr_data_ram_read_count),
    .npr_cmd_ram_read_count     (npr_cmd_ram_read_count),
    .cmpl_data_ram_read_count   (cmpl_data_ram_read_count),
    .cmpl_cmd_ram_read_count    (cmpl_cmd_ram_read_count),
////////////////////////////////////////////////////////////////
    
    //From Encoder
    .csi_after_pr_seq_i         (csi_after_pr_seq),
    .csi_after_pr_seq_valid_i   (csi_after_pr_seq_valid),

    .f2csi_prcmpl_rdy_i         (f2csi_prcmpl_rdy),
    .f2csi_npr_rdy_i            (f2csi_npr_rdy)
    
    );    


/////////////////////Assign statements/////////////////////////////
assign f2csi_prcmpl_rdy[0]  = f2csi_prcmplout_int.rdy[0];
assign f2csi_prcmpl_rdy[1]  = f2csi_prcmplout_int.rdy[1];
assign f2csi_npr_rdy     = f2csi_npr_out_int.rdy;

//Transmit module : payload generator
csi_uport_encode 
 #(
  .TCQ(TCQ)
    ) csi_uport_encode_inst(
        // Ports 
        // Clocks / Resets
        .clk                (clk),
        .rst_n              ((rst_n & (~soft_rst))),     
        //From Generator     
        .pr_data_i          (enc_pr_data),  
        .pr_data_s1_i       (enc_pr_data_s1),   
        .cmpl_data_i        (enc_cmpl_data),
        .cmpl_data_s1_i     (enc_cmpl_data_s1),
        .pr_data_valid_i    (enc_pr_data_valid),
        .cmpl_data_valid_i  (enc_cmpl_data_valid),
        .sop_i              (enc_sop),
        .eop_i              (enc_eop),
        .eop_s1_i           (enc_eop_s1),
        .npr_sop_i          (enc_npr_sop),
        .npr_eop_i          (enc_npr_eop),
        .flow_typ_i         (enc_flow_typ),
        .cap_header_i       (enc_cap_header),
        .npr_cap_header_i   (enc_npr_cap_header),
        .credits_used_i     (credits_used),
        //To Credit Manager
        .pr_local_credits_used_o    (pr_local_credits_used),
        .pr_local_credits_avail_o   (pr_local_credits_used_vld),
        .npr_local_credits_used_o   (npr_local_credits_used),
        .npr_local_credits_avail_o  (npr_local_credits_used_vld),
        .cmpl_local_credits_used_o  (cmpl_local_credits_used),
        .cmpl_local_credits_avail_o (cmpl_local_credits_used_vld),
        //To Request Generator
        .csi_after_pr_seq_o         (csi_after_pr_seq),
        .csi_after_pr_seq_valid_o   (csi_after_pr_seq_valid),
        
        //To CSI
        .f2csi_prcmpl_o             (f2csi_prcmplout_int),
        .f2csi_npr_o                (f2csi_npr_out_int)
        
    );

//////////////////////////////////Register Slicing///////////////////////////////////////

cdx5n_reg_slice 
#(
      .C_DATA_WIDTH(323),
      .C_REG_PATHS (1)
)cdx5n_reg_slice_inst
(
              .clk(clk),        
              .rst_n(rst_n),        
              .i_s_vld(f2csi_prcmplout_int.vld[0]),
              .i_s_dat({f2csi_prcmplout_int.err[0],f2csi_prcmplout_int.eop[0],
                        f2csi_prcmplout_int.sop[0],f2csi_prcmplout_int.seg[0]}),
              .o_s_rdy(f2csi_prcmplout_int.rdy[0]),
              .o_m_vld(f2csi_prcmplout.vld[0]),
              .o_m_dat({f2csi_prcmplout.err[0],f2csi_prcmplout.eop[0],
                        f2csi_prcmplout.sop[0],f2csi_prcmplout.seg[0]}),
              .i_m_rdy(f2csi_prcmplout.rdy[0])
                                   
);  

cdx5n_reg_slice 
#(
      .C_DATA_WIDTH(323),
      .C_REG_PATHS (1)
)cdx5n_reg_slice_inst_seg1
(
              .clk(clk),        
              .rst_n(rst_n),        
              .i_s_vld(f2csi_prcmplout_int.vld[1]),
              .i_s_dat({f2csi_prcmplout_int.err[1],f2csi_prcmplout_int.eop[1],
                        f2csi_prcmplout_int.sop[1],f2csi_prcmplout_int.seg[1]}),
              .o_s_rdy(f2csi_prcmplout_int.rdy[1]),
              .o_m_vld(f2csi_prcmplout.vld[1]),
              .o_m_dat({f2csi_prcmplout.err[1],f2csi_prcmplout.eop[1],
                        f2csi_prcmplout.sop[1],f2csi_prcmplout.seg[1]}),
              .i_m_rdy(f2csi_prcmplout.rdy[1])
                                   
);


cdx5n_reg_slice 
#(
      .C_DATA_WIDTH(323),
      .C_REG_PATHS (1)
)cdx5n_reg_slice_inst_npr
(
              .clk(clk),        
              .rst_n(rst_n),        
              .i_s_vld(f2csi_npr_out_int.vld),
              .i_s_dat({f2csi_npr_out_int.err,f2csi_npr_out_int.eop,
                        f2csi_npr_out_int.sop,f2csi_npr_out_int.seg}),
              .o_s_rdy(f2csi_npr_out_int.rdy),
              .o_m_vld(f2csi_npr_out.vld),
              .o_m_dat({f2csi_npr_out.err,f2csi_npr_out.eop,
                        f2csi_npr_out.sop,f2csi_npr_out.seg}),
              .i_m_rdy(f2csi_npr_out.rdy)
                                   
);


//////////////////////From Decoder to CSI_user port//////////////////////////////////////

/*
blk_mem_gen_0 blk_mem_gen0_inst_cmpl_control(
        .clka         (clk),
        .ena          (1'b1),
        .wea          (cmpl_control_ram_we),
        .addra        (cmpl_control_ram_waddr),
        .dina         (cmpl_control_ram_wdata),
        .clkb         (clk),
        .enb          (1'b1),
        .addrb        (cmpl_control_ram_rdaddr), 
        .doutb        (mb_cmpl_control_data));
*/
    
    
uport_if_wrapper uport_if_wrapper_1 (
    
    
    .ACLK_UPORT          (clk),
    .ARESETN_UPORT       ((rst_n)),// | soft_rst_n)),
    .M_AXI_CSI_UPORT_axil_awvalid      (s_axil_awvalid     ),
    .M_AXI_CSI_UPORT_axil_awready      (s_axil_awready     ),
    .M_AXI_CSI_UPORT_axil_wvalid       (s_axil_wvalid      ),
    .M_AXI_CSI_UPORT_axil_wready       (s_axil_wready      ),
    .M_AXI_CSI_UPORT_axil_rvalid       (s_axil_rvalid      ),
    .M_AXI_CSI_UPORT_axil_rready       (s_axil_rready      ),
    .M_AXI_CSI_UPORT_axil_awaddr       (s_axil_awaddr      ),
    .M_AXI_CSI_UPORT_axil_wdata        (s_axil_wdata       ),
    .M_AXI_CSI_UPORT_axil_rdata        (s_axil_rdata       ),
    .M_AXI_CSI_UPORT_axil_arready      (s_axil_arready     ),
    .M_AXI_CSI_UPORT_axil_araddr       (s_axil_araddr      ),
    .M_AXI_CSI_UPORT_axil_arvalid      (s_axil_arvalid     ),
                                             
    .M_AXI_CSI_UPORT_axil_rresp        (s_axil_rresp       ),
    .M_AXI_CSI_UPORT_axil_wstrb        (s_axil_wstrb       ),
                                             
    .M_AXI_CSI_UPORT_axil_bvalid       (s_axil_bvalid      ),
    .M_AXI_CSI_UPORT_axil_bresp        (s_axil_bresp       ),
    .M_AXI_CSI_UPORT_axil_bready       (s_axil_bready      ),
       
       
    //.addrb_cmpl_data      ((32'h0|cmpl_data_ram_rdaddr)), 
    .addrb_npr_cmd        ((32'h0|npr_control_ram_rdaddr)),
    .addrb_npr_data       ((32'h0|npr_data_ram_rdaddr)),
    .addrb_pr_cmd         ((32'h0|pr_control_ram_rdaddr)),
    .addrb_pr_data        ((32'h0|pr_data_ram_rdaddr)),
    //.dinb_cmpl_data       ('b0),
    .dinb_npr_cmd         ('b0),
    .dinb_npr_data        ('b0),
    .dinb_pr_cmd          ('b0),
    .dinb_pr_data         ('b0),
    //.doutb_cmpl_data      (mb_cmpl_data),
    .doutb_npr_cmd        (mb_npr_control_data),
    .doutb_npr_data       (mb_npr_data),
    .doutb_pr_cmd         (mb_pr_control_data),
    .doutb_pr_data        (mb_pr_data),
    //.enb_cmpl_data        (1'b1),
    .enb_npr_cmd          (1'b1),
    .enb_npr_data         (1'b1),
    .enb_pr_cmd           (1'b1),
    .enb_pr_data          (1'b1),
    //.rstb_cmpl_data       (~(rst_n)),// | soft_rst_n)),
    .rstb_npr_cmd         (~(rst_n)),// | soft_rst_n)),
    .rstb_npr_data        (~(rst_n)),// | soft_rst_n)),
    .rstb_pr_cmd          (~(rst_n)),// | soft_rst_n)),
    .rstb_pr_data         (~(rst_n)),// | soft_rst_n)),
    //.web_cmpl_data        ('b0),
    .web_npr_cmd          ('b0),
    .web_npr_data         ('b0),
    .web_pr_cmd           ('b0),
    .web_pr_data          ('b0),
    
    .addra_cmpl_data      ((32'h0|{uport_rd_mem_ram_addr,2'b00})), 
    .douta_cmpl_data      (uport_wr_rd_mem_ram_rdata),
    .wea_cmpl_data        ('b0),
    .addrb_cmpl_data      ((32'h0|{uport_wr_mem_ram_addr,2'b00})), 
    .dinb_cmpl_data       (uport_wr_rd_mem_ram_wdata),
    .web_cmpl_data        (uport_wr_rd_mem_ram_wen),
    .doutb_cmpl_data      (),
    //.doutb_cmpl_data      (uport_wr_rd_mem_ram_rdata),
    .enb_cmpl_data        (1'b1),
    .rstb_cmpl_data       (~(rst_n)),
    
    .addra_cmpl_cmd       ((32'h0|cmpl_control_ram_waddr) ),
    .dina_cmpl_cmd        (cmpl_control_ram_wdata ),
    .wea_cmpl_cmd         (cmpl_control_ram_we ),
    .addrb_cmpl_cmd       ((32'h0|cmpl_control_ram_rdaddr) ),
    .doutb_cmpl_cmd       (mb_cmpl_control_data ),
    .ena_cmpl_cmd         (1'b1),
    .enb_cmpl_cmd         (1'b1),
    .rsta_cmpl_cmd        (~(rst_n)),
    .rstb_cmpl_cmd        (~(rst_n)),

//PR and CMPL seed rams for checker
    .addrb_pr_check_seed (pr_check_seed_ram_raddr),
    //.clkb_pr_check_seed  (clk),
    .dinb_pr_check_seed  ('b0),
    .enb_pr_check_seed   ('b1),
    .doutb_pr_check_seed (mb_pr_check_seed),
    .rstb_pr_check_seed  (~rst_n),
    .web_pr_check_seed   ('b0),

    .addrb_cmpl_check_seed (cmpl_check_seed_ram_raddr),
    //.clkb_cmpl_check_seed  (clk),
    .dinb_cmpl_check_seed  ('b0),
    .enb_cmpl_check_seed   ('b1),
    .doutb_cmpl_check_seed (mb_cmpl_check_seed),
    .rstb_cmpl_check_seed  (~rst_n),
//  .web_pcmpl_check_seed   ('b0),

    .S_AXI_UPORT_araddr       (S_AXI_UPORT_araddr   ),      
    .S_AXI_UPORT_arprot       (S_AXI_UPORT_arprot   ), 
    .S_AXI_UPORT_arready      (S_AXI_UPORT_arready  ), 
    .S_AXI_UPORT_arvalid      (S_AXI_UPORT_arvalid  ), 
    .S_AXI_UPORT_awaddr       (S_AXI_UPORT_awaddr   ), 
    .S_AXI_UPORT_awprot       (S_AXI_UPORT_awprot   ), 
    .S_AXI_UPORT_awready      (S_AXI_UPORT_awready  ), 
    .S_AXI_UPORT_awvalid      (S_AXI_UPORT_awvalid  ), 
    .S_AXI_UPORT_bready       (S_AXI_UPORT_bready   ), 
    .S_AXI_UPORT_bresp        (S_AXI_UPORT_bresp    ), 
    .S_AXI_UPORT_bvalid       (S_AXI_UPORT_bvalid   ), 
    .S_AXI_UPORT_rdata        (S_AXI_UPORT_rdata    ), 
    .S_AXI_UPORT_rready       (S_AXI_UPORT_rready   ), 
    .S_AXI_UPORT_rresp        (S_AXI_UPORT_rresp    ), 
    .S_AXI_UPORT_rvalid       (S_AXI_UPORT_rvalid   ), 
    .S_AXI_UPORT_wdata        (S_AXI_UPORT_wdata    ), 
    .S_AXI_UPORT_wready       (S_AXI_UPORT_wready   ), 
    .S_AXI_UPORT_wstrb        (S_AXI_UPORT_wstrb    ), 
    .S_AXI_UPORT_wvalid       (S_AXI_UPORT_wvalid   ) 
    
    );
    
endmodule    

