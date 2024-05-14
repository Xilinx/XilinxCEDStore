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

module csi_uport_decode 
 #(
  parameter  TCQ                   = 0
    )(
        // Ports 
        // Clocks / Resets
        input                          clk,
        input                          rst_n,
             
        cdx5n_fab_2s_seg_if.in         csi2f_port0_i,
        output reg  [639:0]            pr_data_o,
        output reg  [319:0]            pr_data_p1_o,
        output reg  [639:0]            cmpl_data_o,
        output reg  [319:0]            cmpl_data_p1_o,
        output reg  [255:0]            cmpl_control_ram_data_o,
        output reg  [8:0]              cmpl_control_ram_addr_o,
        output reg                     cmpl_control_ram_we_o,
        output reg  [1:0]              pr_req_o,
        output reg  [1:0]              cmpl_req_o,
        output reg  [8:0]              seg_len_o,                           /// in dwords       
        output      [3:0]              csi_flow_o,
        output reg  [1:0]              dat_chk_st_o,
        output reg  [1:0]              dat_chk_st_d_o,
        output reg  [1:0]              dat_chk_dn_o,
        output reg  [12:0]             crdts_pr_o   ,
        output reg  [12:0]             crdts_npr_o  ,
        output reg  [12:0]             crdts_cmpl_o ,
        output reg                     crdts_vld_o ,
        output reg                     check_p1_o,
        output reg  [1:0]              barrier_cap_detected_o,
        output reg  [1:0]              iob_ctl_cap_detected_o,
        output reg                     cmpl_control_ram_data_ready,
        ///////////PR RAM Interface///////////////////
        output wire [9:0]              uport_wr_mem_ram_addr_o,     // 13 bit address for 1k deep - 64bit width memory
        output wire [9:0]              uport_rd_mem_ram_addr_o,     // 13 bit address for 1k deep - 64bit width memory
        output wire [31:0]             uport_wr_rd_mem_ram_wdata_o,
        input       [31:0]             uport_wr_rd_mem_ram_rdata,
        output wire [3:0]              uport_wr_rd_mem_ram_wen_o	      

       
    ); 
    
    logic     [1:0]     csi_flow_d; 
    logic     [1:0]     dat_chk_st_d;   
    logic   [639:0]     payload;   
    logic   [319:0]     payload_s1;           
    logic     [3:0]     current_state, state_next,previous_state; 
   (*mark_debug = "true"*) logic     [9:0]      rem_data_len;
   (*mark_debug = "true"*) logic     [9:0]      rem_data_len_s1;
    (*mark_debug = "true"*)logic               dat_chk_dn;
    logic               dat_chk_dn_s1;
    logic  [1:0][319:0] capsule_data; 
    logic    [1:0]      capsule_valid;
   (*mark_debug = "true"*) logic    [1:0]      capsule_valid_d;
   (*mark_debug = "true"*) logic    [1:0]      capsule_start_d;
    logic               payload_valid;
    (*mark_debug = "true"*)logic               payload_valid_d;
    logic               payload_valid_s1;
   (*mark_debug = "true"*) logic    [1:0]      capsule_start;
   (*mark_debug = "true"*) logic    [1:0]      capsule_end;
   (*mark_debug = "true"*) logic   [12:0]      crdts_pr;
   (*mark_debug = "true"*) logic   [10:0]      crdts_npr;
    (*mark_debug = "true"*)logic   [12:0]      crdts_cmpl;
   (*mark_debug = "true"*) logic    [1:0]      crdts_vld;
    logic               npr_crdt_vld;
    logic     [4:0]     seg_len;  
    logic     [3:0]     seg_len_s1;
    logic     [4:0]     seg_len_cred;
    (*mark_debug = "true"*)logic     [4:0]     seg_len_cred_d;
    (*mark_debug = "true"*)logic     [9:0]     count_cntrl_cap;
    (*mark_debug = "true"*)logic     [9:0]     count_barrier_cap;
    (*mark_debug = "true"*)logic     [9:0]     count_iob_ctl_cap;
   (*mark_debug = "true"*) logic     [1:0]     barrier_cap_detected_d;
    (*mark_debug = "true"*)logic     [1:0]     iob_ctl_cap_detected_d;
    logic               cmpl_control_ram_we_d;
    logic               cmpl_control_ram_we_d1;
    logic               cmpl_control_ram_we_d2;
    (*mark_debug = "true"*)logic               npr_iob_ctl_cap_detected;
    csi_capsule_t       cap_in_data;
    csi_capsule_t       cap_in_data_d;
    csi_capsule_t       cap_in_data_s1;
    

//Defination of CSI capsule type
typedef enum logic [5:0] {
  CSI_CT_RD_MEM     = 0,    //6'b00_00_00
  CSI_CT_RD_IO      = 1,    //6'b00_00_01
  CSI_CT_RD_CFG0    = 2,    //6'b00_00_10
  CSI_CT_RD_CFG1    = 3,    //6'b00_00_11
  CSI_CT_WR_MEM     = 4,    //6'b00_01_00
  CSI_CT_WR_IO      = 5,    //6'b00_01_01
  CSI_CT_WR_CFG0    = 6,    //6'b00_01_10
  CSI_CT_WR_CFG1    = 7,    //6'b00_01_11
  CSI_CT_FETCHADD   = 8,    //6'b00_10_00
  CSI_CT_SWAP       = 9,    //6'b00_10_01
  CSI_CT_CAS        = 10,   //6'b00_10_10
  CSI_CT_MESSAGE_RQ = 12,   //6'b00_11_00
  CSI_CT_INTERRUPT  = 13,   //6'b00_11_01
  CSI_CT_COMPLETION = 16,   //6'b01_00_00
  CSI_CT_IB_CTL     = 20,   //6'b01_01_00
  CSI_CT_OB_CTL     = 21,   //6'b01_01_01
  CSI_CT_BARRIER    = 22,   //6'b01_01_10
  CSI_CT_INVALID    = 31    //6'11_11_11
} csi_cap_type_def;
/*
//Defination of CSI capsule Flow
typedef enum logic [1:0] {
  CSI_NPR = 0,
  CSI_CMPT = 1,
  CSI_PR = 2
} csi_flow_t;
*/

localparam [3:0] // states required for Data extraction
    st_idle = 4'b0000,
    st_sop = 4'b0001, 
    st_data_extraction = 4'b0010,
    st_sop_eop = 4'b0011,
    st_eop = 4'b0100,
    st_sop_eop_2pkts = 4'b0101,
    st_sop_eop_sop_2pkts = 4'b0110,
    st_eop_sop_eop_2pkts = 4'b0111,
    st_eop_sop_2pkts = 4'b1000;

logic [9:0]      uport_wr_rd_mem_ram_addr_w;    
logic [9:0]      uport_wr_mem_ram_addr_w;    
logic [9:0]      uport_rd_mem_ram_addr_w;    
logic [31:0]     uport_wr_rd_mem_ram_wdata_w;
logic [3:0]      uport_wr_rd_mem_ram_wen_w;
logic [9:0]      uport_wr_rd_mem_ram_addr_reg;  
logic [9:0]      uport_wr_mem_ram_addr_reg;  
logic [9:0]      uport_rd_mem_ram_addr_reg;  
logic [31:0]     uport_wr_rd_mem_ram_wdata_reg;
logic [3:0]      uport_wr_rd_mem_ram_wen_reg;

always_comb
begin
  if(capsule_start_d[0] & capsule_valid_d[0] & ((cap_in_data.hdr.csi_flow == 2'd0) | (cap_in_data.hdr.csi_flow == 2'd2 )))
    uport_wr_rd_mem_ram_addr_w = cap_in_data.ptype.rw.addr;
  else
    uport_wr_rd_mem_ram_addr_w = uport_wr_rd_mem_ram_addr_reg;
end
// Write addr
always_comb
begin
  if(capsule_start_d[0] & capsule_valid_d[0] & ((cap_in_data.hdr.csi_flow == 2'd2 )))
    uport_wr_mem_ram_addr_w = cap_in_data.ptype.rw.addr;
  else
    uport_wr_mem_ram_addr_w = uport_wr_mem_ram_addr_reg;
end
// Read  addr
always_comb
begin
  if(capsule_start_d[0] & capsule_valid_d[0] & ((cap_in_data.hdr.csi_flow == 2'd0) ))
    uport_rd_mem_ram_addr_w = cap_in_data.ptype.rw.addr;
  else
    uport_rd_mem_ram_addr_w = uport_rd_mem_ram_addr_reg;
end

always_comb
begin
  if((cap_in_data.hdr.csi_dw_len <'d2) && (cap_in_data.hdr.csi_flow == 'd2)) 
    uport_wr_rd_mem_ram_wen_w = cap_in_data.ptype.rw.byte_enables;
  else
    uport_wr_rd_mem_ram_wen_w = 'd0;
end

always_comb
begin
  if((cap_in_data.hdr.csi_dw_len <'d2) && (cap_in_data.hdr.csi_flow == 'd2)) 
    uport_wr_rd_mem_ram_wdata_w = payload[31:0]; //pr_data_o;
  else
    uport_wr_rd_mem_ram_wdata_w = uport_wr_rd_mem_ram_wdata_reg; 
end

`XSRREG_AXIMM(clk, rst_n, uport_wr_rd_mem_ram_wdata_reg, uport_wr_rd_mem_ram_wdata_w, '0)
`XSRREG_AXIMM(clk, rst_n, uport_wr_rd_mem_ram_wen_reg, uport_wr_rd_mem_ram_wen_w, '0)
`XSRREG_AXIMM(clk, rst_n, uport_wr_rd_mem_ram_addr_reg, uport_wr_rd_mem_ram_addr_w, '0)
`XSRREG_AXIMM(clk, rst_n, uport_wr_mem_ram_addr_reg, uport_wr_mem_ram_addr_w, '0)
`XSRREG_AXIMM(clk, rst_n, uport_rd_mem_ram_addr_reg, uport_rd_mem_ram_addr_w, '0)

assign uport_wr_rd_mem_ram_wdata_o = uport_wr_rd_mem_ram_wdata_reg;
assign uport_wr_rd_mem_ram_wen_o   = uport_wr_rd_mem_ram_wen_reg;
assign uport_wr_rd_mem_ram_addr_o  = uport_wr_rd_mem_ram_addr_reg;
assign uport_wr_mem_ram_addr_o  = uport_wr_mem_ram_addr_reg;
assign uport_rd_mem_ram_addr_o  = uport_rd_mem_ram_addr_reg;
//////////////////////////////////////

assign csi2f_port0_i.rdy = 2'b11;

always @(posedge clk)
begin
    if(!rst_n) // go to state idle if reset
    begin
        current_state  <= st_idle;
        previous_state <= st_idle;
    end
    else // otherwise update the states
    begin
        current_state  <= state_next;
        previous_state <= current_state;
    end
end


always @(posedge clk)
begin
    if(!rst_n) // go to state idle if reset
    begin
        cmpl_control_ram_addr_o <= 'd0;
        npr_crdt_vld            <= 'd0;
    end
    else // otherwise update the states
    begin
        npr_crdt_vld        <= (cmpl_control_ram_we_o || npr_iob_ctl_cap_detected);
        if(cmpl_control_ram_we_o == 1'b1)
            cmpl_control_ram_addr_o <= cmpl_control_ram_addr_o + 'd1;
    end
end

always @(posedge clk)
begin
    if(!rst_n) 
    begin
        capsule_data          <= 'd0;
        capsule_valid         <= 'd0;
        capsule_valid_d       <= 'd0;
        capsule_start         <= 'd0;
        capsule_start_d       <= 'd0;
        capsule_end           <= 'd0;
        cap_in_data_d         <= 'd0;
        csi_flow_d            <= 'd0;
    end
    else 
    begin
        capsule_data        <= csi2f_port0_i.seg;
        capsule_valid       <= csi2f_port0_i.vld;
        capsule_start       <= csi2f_port0_i.sop;
        capsule_end         <= csi2f_port0_i.eop;
        capsule_valid_d     <= capsule_valid;
        capsule_start_d     <= capsule_start;
        cap_in_data_d       <= cap_in_data;
        csi_flow_d          <= cap_in_data.hdr.csi_flow;
    end
end

always @(posedge clk)
begin
    if(!rst_n) 
    begin
        crdts_cmpl      <= 'd0;
        crdts_pr        <= 'd0;
        crdts_npr       <= 'd0;
        crdts_pr_o      <= 'd0;
        crdts_npr_o     <= 'd0;
        crdts_cmpl_o    <= 'd0;
        crdts_vld_o     <= 'd0;
    end
    else 
    begin
        crdts_vld_o     <= crdts_vld[0]|| crdts_vld[1] || npr_crdt_vld;
        if(crdts_vld[0] == 1'b1)
        begin           
            crdts_pr_o      <= crdts_pr;
            crdts_cmpl_o    <= crdts_cmpl;
            if(pr_req_o[1] == 'b1 && ((pr_req_o[0] == 'b1 && (seg_len_cred_d <'d5))))
            begin
                crdts_pr     <= 'd3;
            end
            else if(pr_req_o[1] == 'b1 || (pr_req_o[0] == 'b1 && (seg_len_cred_d > 'd15)))
            begin
                crdts_pr     <= 'd4;
            end
            else if(pr_req_o[0] == 'd1 && (seg_len_cred_d > 'd10))
            begin
                crdts_pr     <= 'd3;
            end
            else if(pr_req_o[0] == 'd1 && (seg_len_cred_d > 'd5))
            begin
                crdts_pr     <= 'd2;
            end
            else if(pr_req_o[0] == 'd1)
            begin
                crdts_pr     <= 'd1;
            end
            else
            begin
                crdts_pr        <= 'd0;
            end
            if(((|barrier_cap_detected_d) || (|iob_ctl_cap_detected_d)) && (csi_flow_d == 'd1))
            begin 
                crdts_cmpl     <= 'd2;
            end
            else if(cmpl_req_o[1] == 'b1 && (cmpl_req_o[0] == 'b1 && (seg_len_cred_d < 'd5)))
            begin
                crdts_cmpl     <= 'd3;
            end
            else if(cmpl_req_o == 'b11 || (cmpl_req_o[0] == 'b1 && (seg_len_cred_d > 'd15)))
            begin
                crdts_cmpl     <= 'd4;
            end
            else if(cmpl_req_o[0] == 'b1 && (seg_len_cred_d > 'd10))
            begin
                crdts_cmpl     <= 'd3;
            end
            else if(cmpl_req_o[0] == 'b1 && (seg_len_cred_d > 'd5))
            begin
                crdts_cmpl     <= 'd2;
            end
            else if(cmpl_req_o[0] == 'b1)
            begin
                crdts_cmpl     <= 'd1;
            end
            else
            begin
                crdts_cmpl      <= 'd0;
            end
        end
        else 
        begin
            crdts_pr_o      <= 'd0;
            crdts_cmpl_o    <= 'd0;
            if(pr_req_o[1] == 'b1 && ((pr_req_o[0] == 'b1 && (seg_len_cred_d <'d5))))
            begin
                crdts_pr     <= crdts_pr + 'd3;
            end
            else if(pr_req_o[1] == 'b1 || (pr_req_o[0] == 'b1 && (seg_len_cred_d > 'd15)))
            begin
                crdts_pr     <= crdts_pr + 'd4;
            end
            else if(pr_req_o[0] == 'd1 && (seg_len_cred_d > 'd10))
            begin
                crdts_pr     <= crdts_pr + 'd3;
            end
            else if(pr_req_o[0] == 'd1 && (seg_len_cred_d > 'd5))
            begin
                crdts_pr     <= crdts_pr + 'd2;
            end
            else if(pr_req_o[0] == 'd1)
            begin
                crdts_pr     <= crdts_pr + 'd1;
            end
            else
            begin
                crdts_pr        <= 'd0;
            end
            if(((|barrier_cap_detected_d) || (|iob_ctl_cap_detected_d)) && (csi_flow_d == 'd1))
            begin 
                crdts_cmpl     <= crdts_cmpl + 'd2;
            end
            else if(cmpl_req_o[1] == 'b1 && (cmpl_req_o[0] == 'b1 && (seg_len_cred_d < 'd5)))
            begin
                crdts_cmpl     <= crdts_cmpl + 'd3;
            end
            else if(cmpl_req_o == 'b11 || (cmpl_req_o[0] == 'b1 && (seg_len_cred_d > 'd15)))
            begin
                crdts_cmpl     <= crdts_cmpl + 'd4;
            end
            else if(cmpl_req_o[0] == 'b1 && (seg_len_cred_d > 'd10))
            begin
                crdts_cmpl     <= crdts_cmpl + 'd3;
            end
            else if(cmpl_req_o[0] == 'b1 && (seg_len_cred_d > 'd5))
            begin
                crdts_cmpl     <= crdts_cmpl + 'd2;
            end
            else if(cmpl_req_o[0] == 'b1)
            begin
                crdts_cmpl     <= crdts_cmpl + 'd1;
            end
            else
            begin
                crdts_cmpl      <= 'd0;
            end
        end 
        if(npr_crdt_vld == 'b1)
        begin
            crdts_npr_o    <= crdts_npr;
            if(cmpl_control_ram_we_o || npr_iob_ctl_cap_detected)
                crdts_npr      <= 'd2;
            else
                crdts_npr      <= 'd0;    
        end
        else if(cmpl_control_ram_we_o || npr_iob_ctl_cap_detected)
        begin
            crdts_npr     <= 'd2;
            crdts_npr_o   <= 'd0;
        end
        else
        begin
            crdts_npr_o   <= 'd0;
        end
    end
end

  
always_comb   
begin
   // store current state as next
    state_next = current_state; // required: when no case statement is satisfied
    case(current_state)
        st_idle: begin
            if(csi2f_port0_i.vld[0] == 'b1) 
            begin
                if(csi2f_port0_i.vld[1] == 'b1)  
                begin 
                    case({csi2f_port0_i.sop,csi2f_port0_i.eop})     //sop1,sop0,eop1,eop0
                        4'b1111: state_next = st_sop_eop_2pkts; 
                        4'b1101: state_next = st_sop_eop_sop_2pkts; 
                        //1011: state_next = st_eop_sop_eop_2pkts; 
                        //1001: state_next = st_eop_sop_2pkts;  
                        4'b0100: state_next = st_sop; 
                        4'b0110: state_next = st_sop_eop; 
                        //0000: state_next = st_data_extraction; 
                        //0010: state_next = st_eop; 
                        default : state_next = st_idle; 
                    endcase
                end
                else if(csi2f_port0_i.sop[0] == 'b1 && csi2f_port0_i.eop[0] == 'b1)  
                begin 
                    state_next = st_sop_eop; 
                end
                else if (csi2f_port0_i.sop[0] == 'b1)
                begin
                    state_next = st_sop; 
                end
            end
        end 
        st_sop: begin
            if(csi2f_port0_i.vld[0] == 'b1) 
            begin
                if(csi2f_port0_i.vld[1] == 'b1)  
                begin 
                    case({csi2f_port0_i.sop,csi2f_port0_i.eop})     //sop1,sop0,eop1,eop0
                        //1111: state_next = st_sop_eop_2pkts; 
                        //1101: state_next = st_sop_eop_sop_2pkts; 
                        4'b1011: state_next = st_eop_sop_eop_2pkts; 
                        4'b1001: state_next = st_eop_sop_2pkts;  
                        //0100: state_next = st_sop; 
                        //0110: state_next = st_sop_eop; 
                        4'b0000: state_next = st_data_extraction; 
                        4'b0010: state_next = st_eop; 
                        default : state_next = st_idle; 
                    endcase
                end
                else if(csi2f_port0_i.eop[0] == 'b1) 
                begin 
                    state_next = st_eop;
                end
                else        
                begin 
                    state_next = st_data_extraction; 
                end
            end
        end 
        st_data_extraction: begin
            if(csi2f_port0_i.vld[0] == 'b1)      
            begin           
               if(csi2f_port0_i.vld[1] == 'b1)  
                begin 
                    case({csi2f_port0_i.sop,csi2f_port0_i.eop})     //sop1,sop0,eop1,eop0
                        //1111: state_next = st_sop_eop_2pkts; 
                        //1101: state_next = st_sop_eop_sop_2pkts; 
                        4'b1011: state_next = st_eop_sop_eop_2pkts; 
                        4'b1001: state_next = st_eop_sop_2pkts;  
                        //0100: state_next = st_sop; 
                        //0110: state_next = st_sop_eop; 
                        4'b0000: state_next = st_data_extraction; 
                        4'b0010: state_next = st_eop; 
                        default : state_next = st_idle; 
                    endcase
                end
                else if(csi2f_port0_i.eop[0] == 'b1 ) 
                begin 
                    state_next = st_eop;
                end
            end 
        end
        st_sop_eop: begin
            if(csi2f_port0_i.vld[0] == 'b1) 
            begin   
               if(csi2f_port0_i.vld[1] == 'b1)  
                begin 
                    case({csi2f_port0_i.sop,csi2f_port0_i.eop})     //sop1,sop0,eop1,eop0
                        4'b1111: state_next = st_sop_eop_2pkts; 
                        4'b1101: state_next = st_sop_eop_sop_2pkts; 
                        //1011: state_next = st_eop_sop_eop_2pkts; 
                        //1001: state_next = st_eop_sop_2pkts;  
                        4'b0100: state_next = st_sop; 
                        4'b0110: state_next = st_sop_eop; 
                        //0000: state_next = st_data_extraction; 
                        //0010: state_next = st_eop; 
                        default : state_next = st_idle; 
                    endcase
                end
                else if(csi2f_port0_i.eop[0] == 'b1 && csi2f_port0_i.sop[0] == 'b1) 
                begin 
                    state_next = st_sop_eop;
                end
                else if(csi2f_port0_i.sop[0] == 'b1)        
                begin 
                    state_next = st_sop; 
                end
                else        
                begin 
                    state_next = st_idle; 
                end
           end
           else     
           begin 
            state_next = st_idle; 
           end
        end
        st_eop: begin
            if(csi2f_port0_i.vld[0] == 'b1) 
            begin
               if(csi2f_port0_i.vld[1] == 'b1)  
                begin 
                    case({csi2f_port0_i.sop,csi2f_port0_i.eop})     //sop1,sop0,eop1,eop0
                        4'b1111: state_next = st_sop_eop_2pkts; 
                        4'b1101: state_next = st_sop_eop_sop_2pkts; 
                        //1011: state_next = st_eop_sop_eop_2pkts; 
                        //1001: state_next = st_eop_sop_2pkts;  
                        4'b0100: state_next = st_sop; 
                        4'b0110: state_next = st_sop_eop; 
                        //0000: state_next = st_data_extraction; 
                        //0010: state_next = st_eop; 
                        default : state_next = st_idle; 
                    endcase
                end
                else if(csi2f_port0_i.eop[0] == 'b1 && csi2f_port0_i.sop[0] == 'b1) 
                begin 
                    state_next = st_sop_eop;
                end
                else if(csi2f_port0_i.sop[0] == 'b1)        
                begin 
                    state_next = st_sop; 
                end
                else        
                begin 
                    state_next = st_idle; 
                end
            end
            else
            begin
                state_next = st_idle;
            end
        end
        st_sop_eop_2pkts: begin
            if(csi2f_port0_i.vld[0] == 'b1) 
            begin
               if(csi2f_port0_i.vld[1] == 'b1)  
                begin 
                    case({csi2f_port0_i.sop,csi2f_port0_i.eop})     //sop1,sop0,eop1,eop0
                        4'b1111: state_next = st_sop_eop_2pkts; 
                        4'b1101: state_next = st_sop_eop_sop_2pkts; 
                        //1011: state_next = st_eop_sop_eop_2pkts; 
                        //1001: state_next = st_eop_sop_2pkts;  
                        4'b0100: state_next = st_sop; 
                        4'b0110: state_next = st_sop_eop; 
                        //0000: state_next = st_data_extraction; 
                        //0010: state_next = st_eop; 
                        default : state_next = st_idle; 
                    endcase
                end
                else if(csi2f_port0_i.eop[0] == 'b1 && csi2f_port0_i.sop[0] == 'b1) 
                begin 
                    state_next = st_sop_eop;
                end
                else if(csi2f_port0_i.sop[0] == 'b1)        
                begin 
                    state_next = st_sop; 
                end
                else        
                begin 
                    state_next = st_idle; 
                end
            end
            else
            begin
                state_next = st_idle;
            end
        end
        st_sop_eop_sop_2pkts: begin
            if(csi2f_port0_i.vld[0] == 'b1) 
            begin
               if(csi2f_port0_i.vld[1] == 'b1)  
                begin 
                    case({csi2f_port0_i.sop,csi2f_port0_i.eop})     //sop1,sop0,eop1,eop0
                        //1111: state_next = st_sop_eop_2pkts; 
                        //1101: state_next = st_sop_eop_sop_2pkts; 
                        4'b1011: state_next = st_eop_sop_eop_2pkts; 
                        4'b1001: state_next = st_eop_sop_2pkts;  
                        //0100: state_next = st_sop; 
                        //0110: state_next = st_sop_eop; 
                        4'b0000: state_next = st_data_extraction; 
                        4'b0010: state_next = st_eop; 
                        default : state_next = st_idle; 
                    endcase
                end
                else if(csi2f_port0_i.eop[0] == 'b1) 
                begin 
                    state_next = st_eop;
                end
                else        
                begin 
                    state_next = st_data_extraction; 
                end
            end
        end
        st_eop_sop_eop_2pkts: begin
            if(csi2f_port0_i.vld[0] == 'b1) 
            begin
               if(csi2f_port0_i.vld[1] == 'b1)  
                begin 
                    case({csi2f_port0_i.sop,csi2f_port0_i.eop})     //sop1,sop0,eop1,eop0
                        4'b1111: state_next = st_sop_eop_2pkts; 
                        4'b1101: state_next = st_sop_eop_sop_2pkts; 
                        //1011: state_next = st_eop_sop_eop_2pkts; 
                        //1001: state_next = st_eop_sop_2pkts;  
                        4'b0100: state_next = st_sop; 
                        4'b0110: state_next = st_sop_eop; 
                        //0000: state_next = st_data_extraction; 
                        //0010: state_next = st_eop; 
                        default : state_next = st_idle; 
                    endcase
                end
                else if(csi2f_port0_i.eop[0] == 'b1 && csi2f_port0_i.sop[0] == 'b1) 
                begin 
                    state_next = st_sop_eop;
                end
                else if(csi2f_port0_i.sop[0] == 'b1)        
                begin 
                    state_next = st_sop; 
                end
                else        
                begin 
                    state_next = st_idle; 
                end
            end
            else
            begin
                state_next = st_idle;
            end
        end
        st_eop_sop_2pkts: begin                                  // end [0]  start[1] 
            if(csi2f_port0_i.vld[0] == 'b1) 
            begin
               if(csi2f_port0_i.vld[1] == 'b1)  
                begin 
                    case({csi2f_port0_i.sop,csi2f_port0_i.eop})     //sop1,sop0,eop1,eop0
                        //1111: state_next = st_sop_eop_2pkts; 
                        //1101: state_next = st_sop_eop_sop_2pkts; 
                        4'b1011: state_next = st_eop_sop_eop_2pkts; 
                        4'b1001: state_next = st_eop_sop_2pkts;  
                        //0100: state_next = st_sop; 
                        //0110: state_next = st_sop_eop; 
                        4'b0000: state_next = st_data_extraction; 
                        4'b0010: state_next = st_eop; 
                        default : state_next = st_idle; 
                    endcase
                end
                else if(csi2f_port0_i.eop[0] == 'b1) 
                begin 
                    state_next = st_eop;
                end
                else        
                begin 
                    state_next = st_data_extraction; 
                end
            end
        end
        default:
             state_next = st_idle; 
    endcase
end

always_ff @(posedge clk)
begin
   if(!rst_n)
   begin
      payload              <= 'd0;
      rem_data_len         <= 'd0;
      seg_len              <= 'd0;    //length in Dwords
      seg_len_s1           <= 'd0;    //length in Dwords for seg 1
      payload_s1           <= 'd0;
      rem_data_len_s1      <= 'd0;
      dat_chk_st_o         <= 'd0;
      dat_chk_dn           <= 'd0;
      payload_valid        <= 'd0;
      dat_chk_dn_s1        <= 'd0;
      payload_valid_s1     <= 'd0;
      seg_len_cred         <= 'd0;
      cap_in_data          <= 'd0;
      cap_in_data_s1       <= 'd0;
      barrier_cap_detected_o <= 'd0;
      iob_ctl_cap_detected_o <= 'd0;
   end
   else
   begin   
      case(current_state)
        st_idle: begin
            payload              <= 'd0;
            rem_data_len         <= 'd0;
            seg_len              <= 'd0;      //length in Dwords
            dat_chk_st_o         <= 'd0;
            dat_chk_dn           <= 'd0;
            payload_valid        <= 'd0;
            seg_len_s1           <= 'd0;      //length in Dwords for seg 1
            payload_s1           <= 'd0;
            rem_data_len_s1      <= 'd0;
            dat_chk_dn_s1        <= 'd0;
            payload_valid_s1     <= 'd0;
            check_p1_o           <= 'd0;   
            seg_len_cred         <= 'd0;        
            cap_in_data          <= 'd0;    
            cap_in_data_s1       <= 'd0;    
            barrier_cap_detected_o <= 'd0;          
            iob_ctl_cap_detected_o <= 'd0;          
        end
        st_sop : begin
        if(capsule_valid[0])
        begin           
 ////////// Fixed header extraction 48 bits
            cap_in_data.hdr.csi_type                  <= csi_cap_type_t'(capsule_data[0][5:0]);
            cap_in_data.hdr.csi_flow                  <= csi_flow_t'(capsule_data[0][7:6]);
            cap_in_data.hdr.csi_has_payload           <= capsule_data[0][8:8];
            cap_in_data.hdr.csi_has_payload_check     <= capsule_data[0][9:9];      // not required for data extraction 
            cap_in_data.hdr.csi_dw_len                <= capsule_data[0][19:10];    // length obtained in dword.1 dword = 32 bits
            cap_in_data.hdr.src.info.csi_vc           <= capsule_data[0][23:20];    // only 0th VC used
            cap_in_data.hdr.src.info.csi_src          <= capsule_data[0][28:24];
            cap_in_data.hdr.src.csi_dst_fifo          <= capsule_data[0][28:20];
            cap_in_data.hdr.csi_dst                   <= capsule_data[0][33:29];    // capsule already routed to destination ,not required
            cap_in_data.hdr.pr.info.csi_rro           <= capsule_data[0][34:34];
            cap_in_data.hdr.pr.info.csi_after_pr_seq  <= capsule_data[0][42:35];
            cap_in_data.hdr.csi_poison                <= capsule_data[0][43];
            cap_in_data.hdr.csi_is_managed            <= capsule_data[0][44];
            cap_in_data.hdr.csi_reserved              <= 'd0;
            dat_chk_st_o                              <= 'b01;
            dat_chk_dn                                <= 'd0;
            payload_valid                             <= 'd0;
            seg_len_s1                                <= 'd0;     //length in Dwords for seg 1
            payload_s1                                <= 'd0;
            rem_data_len_s1                           <= 'd0;
            dat_chk_dn_s1                             <= 'd0;
            payload_valid_s1                          <= 'd0;
            check_p1_o                                <= 'd0;
            barrier_cap_detected_o                      <= 'd0;
            if(((csi_cap_type_t'(capsule_data[0][5:0])) == CSI_CT_IB_CTL ) ||
               ((csi_cap_type_t'(capsule_data[0][5:0])) == CSI_CT_OB_CTL ))
            begin
                iob_ctl_cap_detected_o                 <= 'd1;
            end 
            else
                iob_ctl_cap_detected_o                 <= 'd0;
 ////////// Variable header extraction 165 bits
            case(capsule_data[0][5:0])
                CSI_CT_COMPLETION:begin
                    cap_in_data.ptype.cmpl.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.cmpl.completer                 <= capsule_data[0][66:51];
                    cap_in_data.ptype.cmpl.requester                 <= capsule_data[0][82:67];
                    cap_in_data.ptype.cmpl.request_type              <= csi_cap_type_t'(capsule_data[0][88:83]);
                    cap_in_data.ptype.cmpl.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[0][90:89]);
                    cap_in_data.ptype.cmpl.status                    <= csi_cpl_status_t'(capsule_data[0][93:91]);
                    cap_in_data.ptype.cmpl.tc                        <= capsule_data[0][96:94];
                    cap_in_data.ptype.cmpl.tag                       <= capsule_data[0][106:97];
                    cap_in_data.ptype.cmpl.lower_addr                <= capsule_data[0][113:107];
                    cap_in_data.ptype.cmpl.byte_count                <= capsule_data[0][126:114];
                    cap_in_data.ptype.cmpl.is_first                  <= capsule_data[0][127];
                    cap_in_data.ptype.cmpl.is_last                   <= capsule_data[0][128];
                    cap_in_data.ptype.cmpl.rsv                       <= 'd0;    
                    if((csi_cap_type_t'(capsule_data[0][88:83])) == CSI_CT_BARRIER )
                    begin
                        barrier_cap_detected_o[0]                      <= 'b1;
                    end 
                    else
                        barrier_cap_detected_o[0]                      <= 'b0;
                end   
                CSI_CT_RD_MEM,CSI_CT_SWAP,CSI_CT_CAS,CSI_CT_FETCHADD:begin                                       //NPR request
                    cap_in_data.ptype.rw.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.rw.requester                 <= capsule_data[0][66:51];
                    cap_in_data.ptype.rw.completer                 <= capsule_data[0][82:67];
                    cap_in_data.ptype.rw.completer_set             <= capsule_data[0][83];
                    cap_in_data.ptype.rw.addr                      <= capsule_data[0][145:84];
                    cap_in_data.ptype.rw.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[0][147:146]);
                    cap_in_data.ptype.rw.byte_enables              <= capsule_data[0][155:148];
                    cap_in_data.ptype.rw.pasid                     <= capsule_data[0][178:156];                          
                    cap_in_data.ptype.rw.tc                        <= capsule_data[0][181:179];                        
                    cap_in_data.ptype.rw.tph                       <= capsule_data[0][192:182];
                    cap_in_data.ptype.rw.tag                       <= capsule_data[0][202:193];
                    cap_in_data.ptype.rw.secure                    <= capsule_data[0][203];
                    cap_in_data.ptype.rw.trusted                   <= capsule_data[0][204];
                    cap_in_data.ptype.rw.ide_enable                <= capsule_data[0][205];
                    cap_in_data.ptype.rw.rsv                       <= 'd0;
                end 
                CSI_CT_WR_MEM:begin                                       //PR request
                    cap_in_data.ptype.rw.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.rw.requester                 <= capsule_data[0][66:51];
                    cap_in_data.ptype.rw.completer                 <= capsule_data[0][82:67];
                    cap_in_data.ptype.rw.completer_set             <= capsule_data[0][83];
                    cap_in_data.ptype.rw.addr                      <= capsule_data[0][145:84];
                    cap_in_data.ptype.rw.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[0][147:146]);
                    cap_in_data.ptype.rw.byte_enables              <= capsule_data[0][155:148];
                    cap_in_data.ptype.rw.pasid                     <= capsule_data[0][178:156];                          
                    cap_in_data.ptype.rw.tc                        <= capsule_data[0][181:179];                        
                    cap_in_data.ptype.rw.tph                       <= capsule_data[0][192:182];
                    cap_in_data.ptype.rw.tag                       <= capsule_data[0][202:193];
                    cap_in_data.ptype.rw.secure                    <= capsule_data[0][203];
                    cap_in_data.ptype.rw.trusted                   <= capsule_data[0][204];
                    cap_in_data.ptype.rw.ide_enable                <= capsule_data[0][205];
                    cap_in_data.ptype.rw.rsv                       <= 'd0;
                end
                CSI_CT_MESSAGE_RQ : begin                
                    cap_in_data.ptype.msg.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.msg.requester                 <= capsule_data[0][66:51];;
                    cap_in_data.ptype.msg.msg_cookie                <= csi_msg_cookie_t'(capsule_data[0][74:67]);
                    cap_in_data.ptype.msg.secure                    <= capsule_data[0][75];
                    cap_in_data.ptype.msg.trusted                   <= capsule_data[0][76];
                    cap_in_data.ptype.msg.ide_enable                <= capsule_data[0][77];
                    cap_in_data.ptype.msg.msg_tlp_hdr.fmt   <= capsule_data[0][205:203];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ptype   <= capsule_data[0][202:198];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t9   <= capsule_data[0][197];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tc  <= capsule_data[0][196:194];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t8  <= capsule_data[0][193];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr2  <= capsule_data[0][192];
                    cap_in_data.ptype.msg.msg_tlp_hdr.rsvd  <= capsule_data[0][191];
                    cap_in_data.ptype.msg.msg_tlp_hdr.th <= capsule_data[0][190];
                    cap_in_data.ptype.msg.msg_tlp_hdr.td  <= capsule_data[0][189];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ep  <= capsule_data[0][188];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr1_0  <= capsule_data[0][187:186];
                    cap_in_data.ptype.msg.msg_tlp_hdr.at  <= capsule_data[0][185:184];
                    cap_in_data.ptype.msg.msg_tlp_hdr.length  <= capsule_data[0][183:174];
                    cap_in_data.ptype.msg.msg_tlp_hdr.requester_id  <= capsule_data[0][173:158];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tag  <= capsule_data[0][157:150];
                   // cap_in_data.ptype.msg.msg_tlp_hdr <= csi_msg_tlp_hdr_t' (capsule_data[0][205:86]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.message_code  <= csi_pcie_message_code_t'(capsule_data[0][149:142]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.destination_id  <= capsule_data[0][141:126];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.vendor_id  <= capsule_data[0][125:110];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.subtype  <= capsule_data[0][109:102];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.pci_sig_vdm_bytes  <= capsule_data[0][101:78];
                    cap_in_data.ptype.msg.rsv                       <= 7'd0;
                    
                end    
            endcase
 ////////// ECC Valid 1 bit
 ////////// ECC Value 10 bits
            if(capsule_data[0][8])                     //csi_has_payload if payload is available ,extracting payload
            begin 
                if(capsule_valid[1])
                begin
                    payload       <= {capsule_data[1],capsule_data[0][224 +: 96]};
                    rem_data_len  <= (capsule_data[0][19:10] == 'd0)? 'd4093 :(capsule_data[0][19:10] - 'd13) ;
                    payload_valid <= 'd1;
                    dat_chk_dn    <= 'd0;
                    seg_len       <= 'd13;
                    seg_len_cred  <= 'd20; 
                end
                else
                begin
                    payload       <= capsule_data[0][224 +: 96];
                    rem_data_len  <= (capsule_data[0][19:10] == 'd0)? 'd4093 :(capsule_data[0][19:10] - 'd3) ;
                    payload_valid <= 'd1;
                    dat_chk_dn    <= 'd0;
                    seg_len       <= 'd3;
                    seg_len_cred  <= 'd10; 
                end
            end
            else
            begin
                seg_len       <= 'd0;
                seg_len_cred  <= 'd0; 
            end 
        end 
        else
        begin
            dat_chk_st_o               <= 'd0;
            dat_chk_dn                 <= 'd0;
            payload_valid              <= 'd0;
            dat_chk_dn_s1              <= 'd0;
            payload_valid_s1           <= 'd0;
            barrier_cap_detected_o       <= 'd0;
            iob_ctl_cap_detected_o       <= 'd0;
        end 
        end     
        st_sop_eop: begin
        if(capsule_valid[0])
        begin       
 ////////// Fixed header extraction 48 bits
            cap_in_data.hdr.csi_type                  <= csi_cap_type_t'(capsule_data[0][5:0]);
            cap_in_data.hdr.csi_flow                  <= csi_flow_t'(capsule_data[0][7:6]);
            cap_in_data.hdr.csi_has_payload           <= capsule_data[0][8:8];
            cap_in_data.hdr.csi_has_payload_check     <= capsule_data[0][9:9];       
            cap_in_data.hdr.csi_dw_len                <= capsule_data[0][19:10];      //length pbtained in dword.1 dword = 32 bits
            cap_in_data.hdr.src.info.csi_vc           <= capsule_data[0][23:20];    // only 0th VC used
            cap_in_data.hdr.src.info.csi_src          <= capsule_data[0][28:24];
            cap_in_data.hdr.src.csi_dst_fifo          <= capsule_data[0][28:20];
            cap_in_data.hdr.csi_dst                   <= capsule_data[0][33:29];    // capsule already routed to destination ,not required
            cap_in_data.hdr.pr.info.csi_rro           <= capsule_data[0][34:34];
            cap_in_data.hdr.pr.info.csi_after_pr_seq  <= capsule_data[0][42:35];
            cap_in_data.hdr.csi_poison                <= capsule_data[0][43];
            cap_in_data.hdr.csi_is_managed            <= capsule_data[0][44];
            cap_in_data.hdr.csi_reserved              <= 'd0;
            dat_chk_st_o                              <= 'b01;
            dat_chk_dn                                <= 'd1;
            payload_valid                             <= 'd0;
            rem_data_len                              <= 'd0;
            seg_len_s1                                <= 'd0;
            payload_s1                                <= 'd0;
            rem_data_len_s1                           <= 'd0;
            dat_chk_dn_s1                             <= 'd0;
            payload_valid_s1                          <= 'd0;
            check_p1_o                                <= 'd0;
            barrier_cap_detected_o                      <= 'd0;
            if(((csi_cap_type_t'(capsule_data[0][5:0])) == CSI_CT_IB_CTL ) ||
               ((csi_cap_type_t'(capsule_data[0][5:0])) == CSI_CT_OB_CTL ))
            begin
                iob_ctl_cap_detected_o                 <= 'd1;
            end 
            else
                iob_ctl_cap_detected_o                 <= 'd0;
            
            
 ////////// Variable header extraction 165 bits
            case(capsule_data[0][5:0])
                CSI_CT_COMPLETION:begin
                    cap_in_data.ptype.cmpl.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.cmpl.completer                 <= capsule_data[0][66:51];
                    cap_in_data.ptype.cmpl.requester                 <= capsule_data[0][82:67];
                    cap_in_data.ptype.cmpl.request_type              <= csi_cap_type_t'(capsule_data[0][88:83]);
                    cap_in_data.ptype.cmpl.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[0][90:89]);
                    cap_in_data.ptype.cmpl.status                    <= csi_cpl_status_t'(capsule_data[0][93:91]);
                    cap_in_data.ptype.cmpl.tc                        <= capsule_data[0][96:94];
                    cap_in_data.ptype.cmpl.tag                       <= capsule_data[0][106:97];
                    cap_in_data.ptype.cmpl.lower_addr                <= capsule_data[0][113:107];
                    cap_in_data.ptype.cmpl.byte_count                <= capsule_data[0][126:114];
                    cap_in_data.ptype.cmpl.is_first                  <= capsule_data[0][127];
                    cap_in_data.ptype.cmpl.is_last                   <= capsule_data[0][128];
                    cap_in_data.ptype.cmpl.rsv                       <= 'd0;
                    if((csi_cap_type_t'(capsule_data[0][88:83])) == CSI_CT_BARRIER)
                        barrier_cap_detected_o[0]                      <= 'b1;                      
                    else
                        barrier_cap_detected_o[0]                      <= 'b0;  
                end  
                 CSI_CT_RD_MEM,CSI_CT_SWAP,CSI_CT_CAS,CSI_CT_FETCHADD:begin                                       //NPR request
                    cap_in_data.ptype.rw.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.rw.requester                 <= capsule_data[0][66:51];
                    cap_in_data.ptype.rw.completer                 <= capsule_data[0][82:67];
                    cap_in_data.ptype.rw.completer_set             <= capsule_data[0][83];
                    cap_in_data.ptype.rw.addr                      <= capsule_data[0][145:84];
                    cap_in_data.ptype.rw.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[0][147:146]);
                    cap_in_data.ptype.rw.byte_enables              <= capsule_data[0][155:148];
                    cap_in_data.ptype.rw.pasid                     <= capsule_data[0][178:156];                          
                    cap_in_data.ptype.rw.tc                        <= capsule_data[0][181:179];                        
                    cap_in_data.ptype.rw.tph                       <= capsule_data[0][192:182];
                    cap_in_data.ptype.rw.tag                       <= capsule_data[0][202:193];
                    cap_in_data.ptype.rw.secure                    <= capsule_data[0][203];
                    cap_in_data.ptype.rw.trusted                   <= capsule_data[0][204];
                    cap_in_data.ptype.rw.ide_enable                <= capsule_data[0][205];
                    cap_in_data.ptype.rw.rsv                       <= 'd0;
                end   
                CSI_CT_WR_MEM:begin                                       //PR request
                    cap_in_data.ptype.rw.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.rw.requester                 <= capsule_data[0][66:51];
                    cap_in_data.ptype.rw.completer                 <= capsule_data[0][82:67];
                    cap_in_data.ptype.rw.completer_set             <= capsule_data[0][83];
                    cap_in_data.ptype.rw.addr                      <= capsule_data[0][145:84];
                    cap_in_data.ptype.rw.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[0][147:146]);
                    cap_in_data.ptype.rw.byte_enables              <= capsule_data[0][155:148];
                    cap_in_data.ptype.rw.pasid                     <= capsule_data[0][178:156];                          
                    cap_in_data.ptype.rw.tc                        <= capsule_data[0][181:179];                        
                    cap_in_data.ptype.rw.tph                       <= capsule_data[0][192:182];
                    cap_in_data.ptype.rw.tag                       <= capsule_data[0][202:193];
                    cap_in_data.ptype.rw.secure                    <= capsule_data[0][203];
                    cap_in_data.ptype.rw.trusted                   <= capsule_data[0][204];
                    cap_in_data.ptype.rw.ide_enable                <= capsule_data[0][205];
                    cap_in_data.ptype.rw.rsv                       <= 'd0;
                end 
                CSI_CT_MESSAGE_RQ : begin                
                    
                    cap_in_data.ptype.msg.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.msg.requester                 <= capsule_data[0][66:51];;
                    cap_in_data.ptype.msg.msg_cookie                <= csi_msg_cookie_t'(capsule_data[0][74:67]);
                    cap_in_data.ptype.msg.secure                    <= capsule_data[0][75];
                    cap_in_data.ptype.msg.trusted                   <= capsule_data[0][76];
                    cap_in_data.ptype.msg.ide_enable                <= capsule_data[0][77];
                    cap_in_data.ptype.msg.msg_tlp_hdr.fmt   <= capsule_data[0][205:203];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ptype   <= capsule_data[0][202:198];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t9   <= capsule_data[0][197];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tc  <= capsule_data[0][196:194];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t8  <= capsule_data[0][193];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr2  <= capsule_data[0][192];
                    cap_in_data.ptype.msg.msg_tlp_hdr.rsvd  <= capsule_data[0][191];
                    cap_in_data.ptype.msg.msg_tlp_hdr.th <= capsule_data[0][190];
                    cap_in_data.ptype.msg.msg_tlp_hdr.td  <= capsule_data[0][189];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ep  <= capsule_data[0][188];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr1_0  <= capsule_data[0][187:186];
                    cap_in_data.ptype.msg.msg_tlp_hdr.at  <= capsule_data[0][185:184];
                    cap_in_data.ptype.msg.msg_tlp_hdr.length  <= capsule_data[0][183:174];
                    cap_in_data.ptype.msg.msg_tlp_hdr.requester_id  <= capsule_data[0][173:158];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tag  <= capsule_data[0][157:150];
                   // cap_in_data.ptype.msg.msg_tlp_hdr <= csi_msg_tlp_hdr_t' (capsule_data[0][205:86]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.message_code  <= csi_pcie_message_code_t'(capsule_data[0][149:142]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.destination_id  <= capsule_data[0][141:126];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.vendor_id  <= capsule_data[0][125:110];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.subtype  <= capsule_data[0][109:102];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.pci_sig_vdm_bytes  <= capsule_data[0][101:78];
                    cap_in_data.ptype.msg.rsv                       <= 7'd0;
                    
                end
         

            endcase
            ////////// ECC Valid 1 bit
            ////////// ECC Value 10 bits
            if(capsule_data[0][8])                     //csi_has_payload if payload is available ,extracting payload
            begin 
                payload           <= {capsule_data[1],capsule_data[0][224 +: 96]};
                payload_valid     <= 'd1;
                seg_len           <= capsule_data[0][19:10];       //same as dw_len
                if(capsule_data[0][9:9]) // if CRC is present  
                    seg_len_cred      <= capsule_data[0][19:10] + 'd8;   //7 dw for header + 1 dw for crc
                else    
                    seg_len_cred      <= capsule_data[0][19:10] + 'd7;   //7 dw for header
            end         
            else                                        // if payload is not available
            begin
                seg_len           <= 'd0;
                seg_len_cred      <= 'd0;   
            end 
        end
        else
        begin
            dat_chk_st_o               <= 'd0;
            dat_chk_dn                 <= 'd0;
            payload_valid              <= 'd0;
            dat_chk_dn_s1              <= 'd0;
            payload_valid_s1           <= 'd0;
            check_p1_o                 <= 'd0;
            barrier_cap_detected_o       <= 'd0;
            iob_ctl_cap_detected_o       <= 'd0;
        end
        end
        st_data_extraction:begin
        if(capsule_valid == 'b11)
        begin
            dat_chk_st_o              <= 'd0;
            payload                   <= {capsule_data[1],capsule_data[0]};
            seg_len                   <= 'd20;
            seg_len_cred              <= 'd20;
            seg_len_s1                <= 'd0;
            dat_chk_dn                <= 'd0;
            payload_valid             <= 'd1;
            payload_s1                <= 'd0;
            rem_data_len_s1           <= 'd0;
            dat_chk_dn_s1             <= 'd0;
            payload_valid_s1          <= 'd0;
            check_p1_o                <= 'd0;
            barrier_cap_detected_o      <= 'd0;
            iob_ctl_cap_detected_o      <= 'd0;
            if(previous_state == st_eop_sop_2pkts || previous_state == st_sop_eop_sop_2pkts)
            begin
                rem_data_len              <= rem_data_len_s1 - 'd20;
            end
            else
            begin
                rem_data_len              <= rem_data_len - 'd20;
            end
        end
        else if(capsule_valid[0])
        begin
            dat_chk_st_o              <= 'd0;
            payload                   <= {'d0,capsule_data[0]};
            seg_len                   <= 'd10;
            seg_len_cred              <= 'd10;
            seg_len_s1                <= 'd0;
            dat_chk_dn                <= 'd0;
            payload_valid             <= 'd1;
            payload_s1                <= 'd0;
            rem_data_len_s1           <= 'd0;
            dat_chk_dn_s1             <= 'd0;
            payload_valid_s1          <= 'd0;
            check_p1_o                <= 'd0;
            barrier_cap_detected_o      <= 'd0;
            iob_ctl_cap_detected_o      <= 'd0;
            if(previous_state == st_eop_sop_2pkts || previous_state == st_sop_eop_sop_2pkts)
            begin
                rem_data_len              <= rem_data_len_s1 - 'd10;
            end
            else
            begin
                rem_data_len              <= rem_data_len - 'd10;
            end
        end 
        else
        begin
            dat_chk_st_o              <= 'd0;
            dat_chk_dn                <= 'd0;
            payload_valid             <= 'd0;
            seg_len_s1                <= 'd0;
            payload_s1                <= 'd0;
            rem_data_len_s1           <= 'd0;
            dat_chk_dn_s1             <= 'd0;
            payload_valid_s1          <= 'd0;
            check_p1_o                <= 'd0;
            barrier_cap_detected_o      <= 'd0;
            iob_ctl_cap_detected_o      <= 'd0;
        end
        end     
        st_eop:begin
        if(capsule_valid[0])
        begin
            dat_chk_st_o              <= 'd0; 
            payload                   <= {capsule_data[1],capsule_data[0]};
            seg_len_s1                <= 'd0; 
            rem_data_len              <= 'd0; 
            dat_chk_dn                <= 'd1;
            payload_valid             <= 'd1;
            payload_s1                <= 'd0;
            rem_data_len_s1           <= 'd0;
            dat_chk_dn_s1             <= 'd0;
            payload_valid_s1          <= 'd0;
            check_p1_o                <= 'd0;
            barrier_cap_detected_o      <= 'd0;
            iob_ctl_cap_detected_o      <= 'd0;
            if(previous_state == st_eop_sop_2pkts || previous_state == st_sop_eop_sop_2pkts)
            begin
                seg_len               <= rem_data_len_s1;
                if(cap_in_data.hdr.csi_has_payload_check) // if CRC is present  
                    seg_len_cred      <= rem_data_len_s1 + 'd1;   // +1 dw for crc
                else    
                    seg_len_cred      <= rem_data_len_s1;
            end                      
            else                     
            begin                    
                seg_len               <= rem_data_len ;
                if(cap_in_data.hdr.csi_has_payload_check) // if CRC is present  
                    seg_len_cred      <= rem_data_len + 'd1;   // +1 dw for crc
                else    
                    seg_len_cred      <= rem_data_len;
            end
        end 
        else
        begin
            dat_chk_st_o              <= 'd0;
            dat_chk_dn                <= 'd0;
            payload_valid             <= 'd0;
            dat_chk_dn_s1             <= 'd0;
            payload_valid_s1          <= 'd0;
            barrier_cap_detected_o      <= 'd0;
            iob_ctl_cap_detected_o      <= 'd0;
        end
        end     
        st_sop_eop_2pkts: begin
        if(capsule_valid == 'b11)
        begin       
 ////////// Fixed header extraction 48 bits
            cap_in_data.hdr.csi_type                     <= csi_cap_type_t'(capsule_data[0][5:0]);
            cap_in_data.hdr.csi_flow                     <= csi_flow_t'(capsule_data[0][7:6]);
            cap_in_data.hdr.csi_has_payload              <= capsule_data[0][8:8];
            cap_in_data.hdr.csi_has_payload_check        <= capsule_data[0][9:9];      // not required for data extraction 
            cap_in_data.hdr.csi_dw_len                   <= capsule_data[0][19:10];      //length pbtained in dword.1 dword = 32 bits
            cap_in_data.hdr.src.info.csi_vc              <= capsule_data[0][23:20];    // only 0th VC used
            cap_in_data.hdr.src.info.csi_src             <= capsule_data[0][28:24];
            cap_in_data.hdr.src.csi_dst_fifo             <= capsule_data[0][28:20];
            cap_in_data.hdr.csi_dst                      <= capsule_data[0][33:29];    // capsule already routed to destination ,not required
            cap_in_data.hdr.pr.info.csi_rro              <= capsule_data[0][34:34];
            cap_in_data.hdr.pr.info.csi_after_pr_seq     <= capsule_data[0][42:35];
            cap_in_data.hdr.csi_poison                   <= capsule_data[0][43];
            cap_in_data.hdr.csi_is_managed               <= capsule_data[0][44];
            cap_in_data.hdr.csi_reserved                 <= 'd0;
            cap_in_data_s1.hdr.csi_type                  <= csi_cap_type_t'(capsule_data[1][5:0]);
            cap_in_data_s1.hdr.csi_flow                  <= csi_flow_t'(capsule_data[1][7:6]);
            cap_in_data_s1.hdr.csi_has_payload           <= capsule_data[1][8:8];
            cap_in_data_s1.hdr.csi_has_payload_check     <= capsule_data[1][9:9];      // not required for data extraction 
            cap_in_data_s1.hdr.csi_dw_len                <= capsule_data[1][19:10];      //length pbtained in dword.1 dword = 32 bits
            cap_in_data_s1.hdr.src.info.csi_vc           <= capsule_data[1][23:20];    // only 0th VC used
            cap_in_data_s1.hdr.src.info.csi_src          <= capsule_data[1][28:24];
            cap_in_data_s1.hdr.src.csi_dst_fifo          <= capsule_data[1][28:20];
            cap_in_data_s1.hdr.csi_dst                   <= capsule_data[1][33:29];    // capsule already routed to destination ,not required
            cap_in_data_s1.hdr.pr.info.csi_rro           <= capsule_data[1][34:34];
            cap_in_data_s1.hdr.pr.info.csi_after_pr_seq  <= capsule_data[1][42:35];
            cap_in_data_s1.hdr.csi_poison                <= capsule_data[1][43];
            cap_in_data_s1.hdr.csi_is_managed            <= capsule_data[1][44];
            dat_chk_st_o                                 <= 'b11;
            dat_chk_dn                                   <= 'd1;
            payload_valid                                <= 'd0;
            rem_data_len                                 <= 'd0; 
            payload_valid_s1                             <= 'd0;
            rem_data_len_s1                              <= 'd0;
            check_p1_o                                   <= 'd1;
            barrier_cap_detected_o                         <= 'd0;
            if((((csi_cap_type_t'(capsule_data[0][5:0])) == CSI_CT_IB_CTL ) ||
               ((csi_cap_type_t'(capsule_data[0][5:0])) == CSI_CT_OB_CTL )) &&
               (((csi_cap_type_t'(capsule_data[1][5:0])) == CSI_CT_IB_CTL ) ||
               ((csi_cap_type_t'(capsule_data[1][5:0])) == CSI_CT_OB_CTL )))
            begin
                iob_ctl_cap_detected_o                 <= 'd3;
            end 
            else if(((csi_cap_type_t'(capsule_data[0][5:0])) == CSI_CT_IB_CTL ) ||
               ((csi_cap_type_t'(capsule_data[0][5:0])) == CSI_CT_OB_CTL ) || 
               ((csi_cap_type_t'(capsule_data[1][5:0])) == CSI_CT_IB_CTL ) ||
               ((csi_cap_type_t'(capsule_data[1][5:0])) == CSI_CT_OB_CTL ))
            begin
                iob_ctl_cap_detected_o                 <= 'd1;
            end 
            else
                iob_ctl_cap_detected_o                 <= 'd0;
            
            
 ////////// Variable header extraction 165 bits
            case(capsule_data[0][5:0])
                CSI_CT_COMPLETION:begin
                    cap_in_data.ptype.cmpl.attr                    <= capsule_data[0][50:48];
                    cap_in_data.ptype.cmpl.completer               <= capsule_data[0][66:51];
                    cap_in_data.ptype.cmpl.requester               <= capsule_data[0][82:67];
                    cap_in_data.ptype.cmpl.request_type            <= csi_cap_type_t'(capsule_data[0][88:83]);
                    cap_in_data.ptype.cmpl.addr_type               <= csi_pcie_addr_type_t'(capsule_data[0][90:89]);
                    cap_in_data.ptype.cmpl.status                  <= csi_cpl_status_t'(capsule_data[0][93:91]);
                    cap_in_data.ptype.cmpl.tc                      <= capsule_data[0][96:94];
                    cap_in_data.ptype.cmpl.tag                     <= capsule_data[0][106:97];
                    cap_in_data.ptype.cmpl.lower_addr              <= capsule_data[0][113:107];
                    cap_in_data.ptype.cmpl.byte_count              <= capsule_data[0][126:114];
                    cap_in_data.ptype.cmpl.is_first                <= capsule_data[0][127];
                    cap_in_data.ptype.cmpl.is_last                 <= capsule_data[0][128];
                    cap_in_data.ptype.cmpl.rsv                     <= 'd0;
                    if((csi_cap_type_t'(capsule_data[0][88:83])) == CSI_CT_BARRIER)
                    begin
                        barrier_cap_detected_o[0]                    <= 'b1;
                    end
                    else
                        barrier_cap_detected_o[0]                    <= 'b0;
                end  
                CSI_CT_RD_MEM,CSI_CT_SWAP,CSI_CT_CAS,CSI_CT_FETCHADD:begin                                       //NPR request
                    cap_in_data.ptype.rw.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.rw.requester                 <= capsule_data[0][66:51];
                    cap_in_data.ptype.rw.completer                 <= capsule_data[0][82:67];
                    cap_in_data.ptype.rw.completer_set             <= capsule_data[0][83];
                    cap_in_data.ptype.rw.addr                      <= capsule_data[0][145:84];
                    cap_in_data.ptype.rw.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[0][147:146]);
                    cap_in_data.ptype.rw.byte_enables              <= capsule_data[0][155:148];
                    cap_in_data.ptype.rw.pasid                     <= capsule_data[0][178:156];                          
                    cap_in_data.ptype.rw.tc                        <= capsule_data[0][181:179];                        
                    cap_in_data.ptype.rw.tph                       <= capsule_data[0][192:182];
                    cap_in_data.ptype.rw.tag                       <= capsule_data[0][202:193];
                    cap_in_data.ptype.rw.secure                    <= capsule_data[0][203];
                    cap_in_data.ptype.rw.trusted                   <= capsule_data[0][204];
                    cap_in_data.ptype.rw.ide_enable                <= capsule_data[0][205];
                    cap_in_data.ptype.rw.rsv                       <= 'd0;
                end   
                CSI_CT_WR_MEM:begin                                       //PR request
                    cap_in_data.ptype.rw.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.rw.requester                 <= capsule_data[0][66:51];
                    cap_in_data.ptype.rw.completer                 <= capsule_data[0][82:67];
                    cap_in_data.ptype.rw.completer_set             <= capsule_data[0][83];
                    cap_in_data.ptype.rw.addr                      <= capsule_data[0][145:84];
                    cap_in_data.ptype.rw.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[0][147:146]);
                    cap_in_data.ptype.rw.byte_enables              <= capsule_data[0][155:148];
                    cap_in_data.ptype.rw.pasid                     <= capsule_data[0][178:156];                          
                    cap_in_data.ptype.rw.tc                        <= capsule_data[0][181:179];                        
                    cap_in_data.ptype.rw.tph                       <= capsule_data[0][192:182];
                    cap_in_data.ptype.rw.tag                       <= capsule_data[0][202:193];
                    cap_in_data.ptype.rw.secure                    <= capsule_data[0][203];
                    cap_in_data.ptype.rw.trusted                   <= capsule_data[0][204];
                    cap_in_data.ptype.rw.ide_enable                <= capsule_data[0][205];
                    cap_in_data.ptype.rw.rsv                       <= 'd0;
                end 
                CSI_CT_MESSAGE_RQ : begin                
                    
                    cap_in_data.ptype.msg.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.msg.requester                 <= capsule_data[0][66:51];;
                    cap_in_data.ptype.msg.msg_cookie                <= csi_msg_cookie_t'(capsule_data[0][74:67]);
                    cap_in_data.ptype.msg.secure                    <= capsule_data[0][75];
                    cap_in_data.ptype.msg.trusted                   <= capsule_data[0][76];
                    cap_in_data.ptype.msg.ide_enable                <= capsule_data[0][77];
                    cap_in_data.ptype.msg.msg_tlp_hdr.fmt   <= capsule_data[0][205:203];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ptype   <= capsule_data[0][202:198];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t9   <= capsule_data[0][197];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tc  <= capsule_data[0][196:194];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t8  <= capsule_data[0][193];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr2  <= capsule_data[0][192];
                    cap_in_data.ptype.msg.msg_tlp_hdr.rsvd  <= capsule_data[0][191];
                    cap_in_data.ptype.msg.msg_tlp_hdr.th <= capsule_data[0][190];
                    cap_in_data.ptype.msg.msg_tlp_hdr.td  <= capsule_data[0][189];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ep  <= capsule_data[0][188];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr1_0  <= capsule_data[0][187:186];
                    cap_in_data.ptype.msg.msg_tlp_hdr.at  <= capsule_data[0][185:184];
                    cap_in_data.ptype.msg.msg_tlp_hdr.length  <= capsule_data[0][183:174];
                    cap_in_data.ptype.msg.msg_tlp_hdr.requester_id  <= capsule_data[0][173:158];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tag  <= capsule_data[0][157:150];
                   // cap_in_data.ptype.msg.msg_tlp_hdr <= csi_msg_tlp_hdr_t' (capsule_data[0][205:86]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.message_code  <= csi_pcie_message_code_t'(capsule_data[0][149:142]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.destination_id  <= capsule_data[0][141:126];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.vendor_id  <= capsule_data[0][125:110];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.subtype  <= capsule_data[0][109:102];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.pci_sig_vdm_bytes  <= capsule_data[0][101:78];
                    cap_in_data.ptype.msg.rsv                       <= 7'd0;
                    
                    
                end    
            endcase
 ////////// Variable header extraction 165 bits for segment 1
            case(capsule_data[1][5:0])
                CSI_CT_COMPLETION:begin
                    cap_in_data_s1.ptype.cmpl.attr                 <= capsule_data[1][50:48];
                    cap_in_data_s1.ptype.cmpl.completer            <= capsule_data[1][66:51];
                    cap_in_data_s1.ptype.cmpl.requester            <= capsule_data[1][82:67];
                    cap_in_data_s1.ptype.cmpl.request_type         <= csi_cap_type_t'(capsule_data[1][88:83]);
                    cap_in_data_s1.ptype.cmpl.addr_type            <= csi_pcie_addr_type_t'(capsule_data[1][90:89]);
                    cap_in_data_s1.ptype.cmpl.status               <= csi_cpl_status_t'(capsule_data[1][93:91]);
                    cap_in_data_s1.ptype.cmpl.tc                   <= capsule_data[1][96:94];
                    cap_in_data_s1.ptype.cmpl.tag                  <= capsule_data[1][106:97];
                    cap_in_data_s1.ptype.cmpl.lower_addr           <= capsule_data[1][113:107];
                    cap_in_data_s1.ptype.cmpl.byte_count           <= capsule_data[1][126:114];
                    cap_in_data_s1.ptype.cmpl.is_first             <= capsule_data[1][127];
                    cap_in_data_s1.ptype.cmpl.is_last              <= capsule_data[1][128];
                    cap_in_data_s1.ptype.cmpl.rsv                  <= 'd0;
                    if((csi_cap_type_t'(capsule_data[1][88:83])) == CSI_CT_BARRIER)
                    begin
                        barrier_cap_detected_o[1]                    <= 'b1;
                    end 
                    else
                        barrier_cap_detected_o[1]                    <= 'b0;
                end  
                 CSI_CT_RD_MEM,CSI_CT_SWAP,CSI_CT_CAS,CSI_CT_FETCHADD:begin                                       //NPR request
                    cap_in_data_s1.ptype.rw.attr                   <= capsule_data[1][50:48];
                    cap_in_data_s1.ptype.rw.requester              <= capsule_data[1][66:51];
                    cap_in_data_s1.ptype.rw.completer              <= capsule_data[1][82:67];
                    cap_in_data_s1.ptype.rw.completer_set          <= capsule_data[1][83];
                    cap_in_data_s1.ptype.rw.addr                   <= capsule_data[1][145:84];
                    cap_in_data_s1.ptype.rw.addr_type              <= csi_pcie_addr_type_t'(capsule_data[1][147:146]);
                    cap_in_data_s1.ptype.rw.byte_enables           <= capsule_data[1][155:148];
                    cap_in_data_s1.ptype.rw.pasid                  <= capsule_data[1][178:156];                          
                    cap_in_data_s1.ptype.rw.tc                     <= capsule_data[1][181:179];                        
                    cap_in_data_s1.ptype.rw.tph                    <= capsule_data[1][192:182];
                    cap_in_data_s1.ptype.rw.tag                    <= capsule_data[1][202:193];
                    cap_in_data_s1.ptype.rw.secure                 <= capsule_data[1][203];
                    cap_in_data_s1.ptype.rw.trusted                <= capsule_data[1][204];
                    cap_in_data_s1.ptype.rw.ide_enable             <= capsule_data[1][205];
                    cap_in_data_s1.ptype.rw.rsv                    <= 'd0;
                end   
                CSI_CT_WR_MEM:begin                                       //PR request
                    cap_in_data_s1.ptype.rw.attr                   <= capsule_data[1][50:48];
                    cap_in_data_s1.ptype.rw.requester              <= capsule_data[1][66:51];
                    cap_in_data_s1.ptype.rw.completer              <= capsule_data[1][82:67];
                    cap_in_data_s1.ptype.rw.completer_set          <= capsule_data[1][83];
                    cap_in_data_s1.ptype.rw.addr                   <= capsule_data[1][145:84];
                    cap_in_data_s1.ptype.rw.addr_type              <= csi_pcie_addr_type_t'(capsule_data[1][147:146]);
                    cap_in_data_s1.ptype.rw.byte_enables           <= capsule_data[1][155:148];
                    cap_in_data_s1.ptype.rw.pasid                  <= capsule_data[1][178:156];                          
                    cap_in_data_s1.ptype.rw.tc                     <= capsule_data[1][181:179];                        
                    cap_in_data_s1.ptype.rw.tph                    <= capsule_data[1][192:182];
                    cap_in_data_s1.ptype.rw.tag                    <= capsule_data[1][202:193];
                    cap_in_data_s1.ptype.rw.secure                 <= capsule_data[1][203];
                    cap_in_data_s1.ptype.rw.trusted                <= capsule_data[1][204];
                    cap_in_data_s1.ptype.rw.ide_enable             <= capsule_data[1][205];
                    cap_in_data_s1.ptype.rw.rsv                    <= 'd0;
                end 
CSI_CT_MESSAGE_RQ : begin                
                    
                    cap_in_data.ptype.msg.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.msg.requester                 <= capsule_data[0][66:51];;
                    cap_in_data.ptype.msg.msg_cookie                <= csi_msg_cookie_t'(capsule_data[0][74:67]);
                    cap_in_data.ptype.msg.secure                    <= capsule_data[0][75];
                    cap_in_data.ptype.msg.trusted                   <= capsule_data[0][76];
                    cap_in_data.ptype.msg.ide_enable                <= capsule_data[0][77];
                    cap_in_data.ptype.msg.msg_tlp_hdr.fmt   <= capsule_data[0][205:203];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ptype   <= capsule_data[0][202:198];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t9   <= capsule_data[0][197];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tc  <= capsule_data[0][196:194];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t8  <= capsule_data[0][193];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr2  <= capsule_data[0][192];
                    cap_in_data.ptype.msg.msg_tlp_hdr.rsvd  <= capsule_data[0][191];
                    cap_in_data.ptype.msg.msg_tlp_hdr.th <= capsule_data[0][190];
                    cap_in_data.ptype.msg.msg_tlp_hdr.td  <= capsule_data[0][189];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ep  <= capsule_data[0][188];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr1_0  <= capsule_data[0][187:186];
                    cap_in_data.ptype.msg.msg_tlp_hdr.at  <= capsule_data[0][185:184];
                    cap_in_data.ptype.msg.msg_tlp_hdr.length  <= capsule_data[0][183:174];
                    cap_in_data.ptype.msg.msg_tlp_hdr.requester_id  <= capsule_data[0][173:158];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tag  <= capsule_data[0][157:150];
                   // cap_in_data.ptype.msg.msg_tlp_hdr <= csi_msg_tlp_hdr_t' (capsule_data[0][205:86]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.message_code  <= csi_pcie_message_code_t'(capsule_data[0][149:142]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.destination_id  <= capsule_data[0][141:126];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.vendor_id  <= capsule_data[0][125:110];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.subtype  <= capsule_data[0][109:102];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.pci_sig_vdm_bytes  <= capsule_data[0][101:78];
                    cap_in_data.ptype.msg.rsv                       <= 7'd0;
                    
                    
                end     

            endcase
 ////////// ECC Valid 1 bit
 ////////// ECC Value 10 bits
            if(capsule_data[0][8])                     //csi_has_payload if payload is available ,extracting payload
            begin 
                payload       <= capsule_data[0][224 +: 96];
                payload_valid <= 'd1;
                seg_len       <= capsule_data[0][19:10];       //same as dw_len  
                if(capsule_data[0][9:9]) // if CRC is present  
                    seg_len_cred      <= capsule_data[0][19:10] + 'd8;   //7 dw for header + 1 dw for crc
                else    
                    seg_len_cred      <= capsule_data[0][19:10] + 'd7;   //7 dw for header
            end     
            else            
            begin
                seg_len       <= 'd0;
                seg_len_cred  <= 'd0;
            end 
            if(capsule_data[1][8])                     //csi_has_payload if payload is available ,extracting payload
            begin 
                payload_s1       <= capsule_data[1][224 +: 96];
                payload_valid_s1 <= 'd1;
                seg_len_s1       <= capsule_data[1][19:10];       //same as dw_len    
            end     
            else            
            begin
                seg_len_s1    <= 'd0;
            end 
        end
        else
        begin
            dat_chk_st_o              <= 'd0;
            dat_chk_dn                <= 'd0;
            payload_valid             <= 'd0;
            dat_chk_dn_s1             <= 'd0;
            payload_valid_s1          <= 'd0;
            check_p1_o                <= 'd0;
            barrier_cap_detected_o      <= 'd0;
            iob_ctl_cap_detected_o      <= 'd0;
        end
        end
        st_sop_eop_sop_2pkts: begin
        if(capsule_valid == 'b11)
        begin       
 ////////// Fixed header extraction 48 bits
            cap_in_data.hdr.csi_type                     <= csi_cap_type_t'(capsule_data[0][5:0]);
            cap_in_data.hdr.csi_flow                     <= csi_flow_t'(capsule_data[0][7:6]);
            cap_in_data.hdr.csi_has_payload              <= capsule_data[0][8:8];
            cap_in_data.hdr.csi_has_payload_check        <= capsule_data[0][9:9];      // not required for data extraction 
            cap_in_data.hdr.csi_dw_len                   <= capsule_data[0][19:10];      //length pbtained in dword.1 dword = 32 bits
            cap_in_data.hdr.src.info.csi_vc              <= capsule_data[0][23:20];    // only 0th VC used
            cap_in_data.hdr.src.info.csi_src             <= capsule_data[0][28:24];
            cap_in_data.hdr.src.csi_dst_fifo             <= capsule_data[0][28:20];
            cap_in_data.hdr.csi_dst                      <= capsule_data[0][33:29];    // capsule already routed to destination ,not required
            cap_in_data.hdr.pr.info.csi_rro              <= capsule_data[0][34:34];
            cap_in_data.hdr.pr.info.csi_after_pr_seq     <= capsule_data[0][42:35];
            cap_in_data.hdr.csi_poison                   <= capsule_data[0][43];
            cap_in_data.hdr.csi_is_managed               <= capsule_data[0][44];
            cap_in_data.hdr.csi_reserved                 <= 'd0;
            cap_in_data_s1.hdr.csi_type                  <= csi_cap_type_t'(capsule_data[1][5:0]);
            cap_in_data_s1.hdr.csi_flow                  <= csi_flow_t'(capsule_data[1][7:6]);
            cap_in_data_s1.hdr.csi_has_payload           <= capsule_data[1][8:8];
            cap_in_data_s1.hdr.csi_has_payload_check     <= capsule_data[1][9:9];      // not required for data extraction 
            cap_in_data_s1.hdr.csi_dw_len                <= capsule_data[1][19:10];      //length pbtained in dword.1 dword = 32 bits
            cap_in_data_s1.hdr.src.info.csi_vc           <= capsule_data[1][23:20];    // only 0th VC used
            cap_in_data_s1.hdr.src.info.csi_src          <= capsule_data[1][28:24];
            cap_in_data_s1.hdr.src.csi_dst_fifo          <= capsule_data[1][28:20];
            cap_in_data_s1.hdr.csi_dst                   <= capsule_data[1][33:29];    // capsule already routed to destination ,not required
            cap_in_data_s1.hdr.pr.info.csi_rro           <= capsule_data[1][34:34];
            cap_in_data_s1.hdr.pr.info.csi_after_pr_seq  <= capsule_data[1][42:35];
            cap_in_data_s1.hdr.csi_poison                <= capsule_data[1][43];
            cap_in_data_s1.hdr.csi_is_managed            <= capsule_data[1][44];
            cap_in_data_s1.hdr.csi_reserved              <= 'd0;
            dat_chk_st_o                                 <= 'b11;
            dat_chk_dn                                   <= 'd1;
            payload_valid                                <= 'd0;
            rem_data_len                                 <= 'd0;
            dat_chk_dn_s1                                <= 'd1;
            payload_valid_s1                             <= 'd0;
            rem_data_len_s1                              <= 'd0; 
            check_p1_o                                   <= 'd0;
            barrier_cap_detected_o                         <= 'd0;
            if((((csi_cap_type_t'(capsule_data[0][5:0])) == CSI_CT_IB_CTL ) ||
               ((csi_cap_type_t'(capsule_data[0][5:0])) == CSI_CT_OB_CTL )) &&
               (((csi_cap_type_t'(capsule_data[1][5:0])) == CSI_CT_IB_CTL ) ||
               ((csi_cap_type_t'(capsule_data[1][5:0])) == CSI_CT_OB_CTL )))
            begin
                iob_ctl_cap_detected_o                 <= 'd3;
            end 
            else if(((csi_cap_type_t'(capsule_data[0][5:0])) == CSI_CT_IB_CTL ) ||
               ((csi_cap_type_t'(capsule_data[0][5:0])) == CSI_CT_OB_CTL ) || 
               ((csi_cap_type_t'(capsule_data[1][5:0])) == CSI_CT_IB_CTL ) ||
               ((csi_cap_type_t'(capsule_data[1][5:0])) == CSI_CT_OB_CTL ))
            begin
                iob_ctl_cap_detected_o                 <= 'd1;
            end 
            else
                iob_ctl_cap_detected_o                 <= 'd0;
            
 ////////// Variable header extraction 165 bits
            case(capsule_data[0][5:0])
                CSI_CT_COMPLETION:begin
                    cap_in_data.ptype.cmpl.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.cmpl.completer                 <= capsule_data[0][66:51];
                    cap_in_data.ptype.cmpl.requester                 <= capsule_data[0][82:67];
                    cap_in_data.ptype.cmpl.request_type              <= csi_cap_type_t'(capsule_data[0][88:83]);
                    cap_in_data.ptype.cmpl.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[0][90:89]);
                    cap_in_data.ptype.cmpl.status                    <= csi_cpl_status_t'(capsule_data[0][93:91]);
                    cap_in_data.ptype.cmpl.tc                        <= capsule_data[0][96:94];
                    cap_in_data.ptype.cmpl.tag                       <= capsule_data[0][106:97];
                    cap_in_data.ptype.cmpl.lower_addr                <= capsule_data[0][113:107];
                    cap_in_data.ptype.cmpl.byte_count                <= capsule_data[0][126:114];
                    cap_in_data.ptype.cmpl.is_first                  <= capsule_data[0][127];
                    cap_in_data.ptype.cmpl.is_last                   <= capsule_data[0][128];
                    cap_in_data.ptype.cmpl.rsv                       <= 'd0;
                    if((csi_cap_type_t'(capsule_data[0][88:83])) == CSI_CT_BARRIER)
                    begin
                        barrier_cap_detected_o[0]                    <= 'b1;
                    end 
                    else
                        barrier_cap_detected_o[0]                    <= 'b0;
                end  
                CSI_CT_RD_MEM,CSI_CT_SWAP,CSI_CT_CAS,CSI_CT_FETCHADD:begin                                       //NPR request
                    cap_in_data.ptype.rw.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.rw.requester                 <= capsule_data[0][66:51];
                    cap_in_data.ptype.rw.completer                 <= capsule_data[0][82:67];
                    cap_in_data.ptype.rw.completer_set             <= capsule_data[0][83];
                    cap_in_data.ptype.rw.addr                      <= capsule_data[0][145:84];
                    cap_in_data.ptype.rw.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[0][147:146]);
                    cap_in_data.ptype.rw.byte_enables              <= capsule_data[0][155:148];
                    cap_in_data.ptype.rw.pasid                     <= capsule_data[0][178:156];                          
                    cap_in_data.ptype.rw.tc                        <= capsule_data[0][181:179];                        
                    cap_in_data.ptype.rw.tph                       <= capsule_data[0][192:182];
                    cap_in_data.ptype.rw.tag                       <= capsule_data[0][202:193];
                    cap_in_data.ptype.rw.secure                    <= capsule_data[0][203];
                    cap_in_data.ptype.rw.trusted                   <= capsule_data[0][204];
                    cap_in_data.ptype.rw.ide_enable                <= capsule_data[0][205];
                    cap_in_data.ptype.rw.rsv                       <= 'd0;
                end   
                CSI_CT_WR_MEM:begin                                       //PR request
                    cap_in_data.ptype.rw.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.rw.requester                 <= capsule_data[0][66:51];
                    cap_in_data.ptype.rw.completer                 <= capsule_data[0][82:67];
                    cap_in_data.ptype.rw.completer_set             <= capsule_data[0][83];
                    cap_in_data.ptype.rw.addr                      <= capsule_data[0][145:84];
                    cap_in_data.ptype.rw.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[0][147:146]);
                    cap_in_data.ptype.rw.byte_enables              <= capsule_data[0][155:148];
                    cap_in_data.ptype.rw.pasid                     <= capsule_data[0][178:156];                          
                    cap_in_data.ptype.rw.tc                        <= capsule_data[0][181:179];                        
                    cap_in_data.ptype.rw.tph                       <= capsule_data[0][192:182];
                    cap_in_data.ptype.rw.tag                       <= capsule_data[0][202:193];
                    cap_in_data.ptype.rw.secure                    <= capsule_data[0][203];
                    cap_in_data.ptype.rw.trusted                   <= capsule_data[0][204];
                    cap_in_data.ptype.rw.ide_enable                <= capsule_data[0][205];
                    cap_in_data.ptype.rw.rsv                       <= 'd0;
                end 

      CSI_CT_MESSAGE_RQ : begin                
                    
                    cap_in_data.ptype.msg.attr                      <= capsule_data[0][50:48];
                    cap_in_data.ptype.msg.requester                 <= capsule_data[0][66:51];;
                    cap_in_data.ptype.msg.msg_cookie                <= csi_msg_cookie_t'(capsule_data[0][74:67]);
                    cap_in_data.ptype.msg.secure                    <= capsule_data[0][75];
                    cap_in_data.ptype.msg.trusted                   <= capsule_data[0][76];
                    cap_in_data.ptype.msg.ide_enable                <= capsule_data[0][77];
                    cap_in_data.ptype.msg.msg_tlp_hdr.fmt   <= capsule_data[0][205:203];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ptype   <= capsule_data[0][202:198];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t9   <= capsule_data[0][197];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tc  <= capsule_data[0][196:194];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t8  <= capsule_data[0][193];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr2  <= capsule_data[0][192];
                    cap_in_data.ptype.msg.msg_tlp_hdr.rsvd  <= capsule_data[0][191];
                    cap_in_data.ptype.msg.msg_tlp_hdr.th <= capsule_data[0][190];
                    cap_in_data.ptype.msg.msg_tlp_hdr.td  <= capsule_data[0][189];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ep  <= capsule_data[0][188];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr1_0  <= capsule_data[0][187:186];
                    cap_in_data.ptype.msg.msg_tlp_hdr.at  <= capsule_data[0][185:184];
                    cap_in_data.ptype.msg.msg_tlp_hdr.length  <= capsule_data[0][183:174];
                    cap_in_data.ptype.msg.msg_tlp_hdr.requester_id  <= capsule_data[0][173:158];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tag  <= capsule_data[0][157:150];
                   // cap_in_data.ptype.msg.msg_tlp_hdr <= csi_msg_tlp_hdr_t' (capsule_data[0][205:86]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.message_code  <= csi_pcie_message_code_t'(capsule_data[0][149:142]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.destination_id  <= capsule_data[0][141:126];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.vendor_id  <= capsule_data[0][125:110];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.subtype  <= capsule_data[0][109:102];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.pci_sig_vdm_bytes  <= capsule_data[0][101:78];
                    cap_in_data.ptype.msg.rsv                       <= 7'd0;
                    
                    
                end     

            endcase
 ////////// Variable header extraction 165 bits for segment 1
            case(capsule_data[1][5:0])
                CSI_CT_COMPLETION:begin
                    cap_in_data_s1.ptype.cmpl.attr                      <= capsule_data[1][50:48];
                    cap_in_data_s1.ptype.cmpl.completer                 <= capsule_data[1][66:51];
                    cap_in_data_s1.ptype.cmpl.requester                 <= capsule_data[1][82:67];
                    cap_in_data_s1.ptype.cmpl.request_type              <= csi_cap_type_t'(capsule_data[1][88:83]);
                    cap_in_data_s1.ptype.cmpl.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[1][90:89]);
                    cap_in_data_s1.ptype.cmpl.status                    <= csi_cpl_status_t'(capsule_data[1][93:91]);
                    cap_in_data_s1.ptype.cmpl.tc                        <= capsule_data[1][96:94];
                    cap_in_data_s1.ptype.cmpl.tag                       <= capsule_data[1][106:97];
                    cap_in_data_s1.ptype.cmpl.lower_addr                <= capsule_data[1][113:107];
                    cap_in_data_s1.ptype.cmpl.byte_count                <= capsule_data[1][126:114];
                    cap_in_data_s1.ptype.cmpl.is_first                  <= capsule_data[1][127];
                    cap_in_data_s1.ptype.cmpl.is_last                   <= capsule_data[1][128];
                    cap_in_data_s1.ptype.cmpl.rsv                       <= 'd0;
                    if((csi_cap_type_t'(capsule_data[1][88:83])) == CSI_CT_BARRIER)
                    begin
                        barrier_cap_detected_o[1]                         <= 'b1;
                    end
                    else
                        barrier_cap_detected_o[1]                         <= 'b0;                   
                end                                                     
                CSI_CT_RD_MEM,CSI_CT_SWAP,CSI_CT_CAS,CSI_CT_FETCHADD:begin                                         //NPR request
                    cap_in_data_s1.ptype.rw.attr                        <= capsule_data[1][50:48];
                    cap_in_data_s1.ptype.rw.requester                   <= capsule_data[1][66:51];
                    cap_in_data_s1.ptype.rw.completer                   <= capsule_data[1][82:67];
                    cap_in_data_s1.ptype.rw.completer_set               <= capsule_data[1][83];
                    cap_in_data_s1.ptype.rw.addr                        <= capsule_data[1][145:84];
                    cap_in_data_s1.ptype.rw.addr_type                   <= csi_pcie_addr_type_t'(capsule_data[1][147:146]);
                    cap_in_data_s1.ptype.rw.byte_enables                <= capsule_data[1][155:148];
                    cap_in_data_s1.ptype.rw.pasid                       <= capsule_data[1][178:156];                          
                    cap_in_data_s1.ptype.rw.tc                          <= capsule_data[1][181:179];                        
                    cap_in_data_s1.ptype.rw.tph                         <= capsule_data[1][192:182];
                    cap_in_data_s1.ptype.rw.tag                         <= capsule_data[1][202:193];
                    cap_in_data_s1.ptype.rw.secure                      <= capsule_data[1][203];
                    cap_in_data_s1.ptype.rw.trusted                     <= capsule_data[1][204];
                    cap_in_data_s1.ptype.rw.ide_enable                  <= capsule_data[1][205];
                    cap_in_data_s1.ptype.rw.rsv                         <= 'd0;
                end   
                CSI_CT_WR_MEM:begin                                       //PR request
                    cap_in_data_s1.ptype.rw.attr                   <= capsule_data[1][50:48];
                    cap_in_data_s1.ptype.rw.requester              <= capsule_data[1][66:51];
                    cap_in_data_s1.ptype.rw.completer              <= capsule_data[1][82:67];
                    cap_in_data_s1.ptype.rw.completer_set          <= capsule_data[1][83];
                    cap_in_data_s1.ptype.rw.addr                   <= capsule_data[1][145:84];
                    cap_in_data_s1.ptype.rw.addr_type              <= csi_pcie_addr_type_t'(capsule_data[1][147:146]);
                    cap_in_data_s1.ptype.rw.byte_enables           <= capsule_data[1][155:148];
                    cap_in_data_s1.ptype.rw.pasid                  <= capsule_data[1][178:156];                          
                    cap_in_data_s1.ptype.rw.tc                     <= capsule_data[1][181:179];                        
                    cap_in_data_s1.ptype.rw.tph                    <= capsule_data[1][192:182];
                    cap_in_data_s1.ptype.rw.tag                    <= capsule_data[1][202:193];
                    cap_in_data_s1.ptype.rw.secure                 <= capsule_data[1][203];
                    cap_in_data_s1.ptype.rw.trusted                <= capsule_data[1][204];
                    cap_in_data_s1.ptype.rw.ide_enable             <= capsule_data[1][205];
                    cap_in_data_s1.ptype.rw.rsv                    <= 'd0;
                end 
                CSI_CT_MESSAGE_RQ : begin                

                    cap_in_data.ptype.msg.attr                      <= capsule_data[1][50:48];
                    cap_in_data.ptype.msg.requester                 <= capsule_data[1][66:51];;
                    cap_in_data.ptype.msg.msg_cookie                <= csi_msg_cookie_t'(capsule_data[1][74:67]);
                    cap_in_data.ptype.msg.secure                    <= capsule_data[1][75];
                    cap_in_data.ptype.msg.trusted                   <= capsule_data[1][76];
                    cap_in_data.ptype.msg.ide_enable                <= capsule_data[1][77];
                    cap_in_data.ptype.msg.msg_tlp_hdr.fmt   <= capsule_data[1][205:203];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ptype   <= capsule_data[1][202:198];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t9   <= capsule_data[1][197];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tc  <= capsule_data[1][196:194];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t8  <= capsule_data[1][193];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr2  <= capsule_data[1][192];
                    cap_in_data.ptype.msg.msg_tlp_hdr.rsvd  <= capsule_data[1][191];
                    cap_in_data.ptype.msg.msg_tlp_hdr.th <= capsule_data[1][190];
                    cap_in_data.ptype.msg.msg_tlp_hdr.td  <= capsule_data[1][189];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ep  <= capsule_data[1][188];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr1_0  <= capsule_data[1][187:186];
                    cap_in_data.ptype.msg.msg_tlp_hdr.at  <= capsule_data[1][185:184];
                    cap_in_data.ptype.msg.msg_tlp_hdr.length  <= capsule_data[1][183:174];
                    cap_in_data.ptype.msg.msg_tlp_hdr.requester_id  <= capsule_data[1][173:158];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tag  <= capsule_data[1][157:150];
                   // cap_in_data.ptype.msg.msg_tlp_hdr <= csi_msg_tlp_hdr_t' (capsule_data[1][205:86]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.message_code  <= csi_pcie_message_code_t'(capsule_data[1][149:142]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.destination_id  <= capsule_data[1][141:126];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.vendor_id  <= capsule_data[1][125:110];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.subtype  <= capsule_data[1][109:102];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.pci_sig_vdm_bytes  <= capsule_data[1][101:78];
                    cap_in_data.ptype.msg.rsv                       <= 7'd0;

                end     
                     

            endcase
 ////////// ECC Valid 1 bit
 ////////// ECC Value 10 bits
            if(capsule_data[0][8])                     //csi_has_payload if payload is available ,extracting payload
            begin 
                payload       <= capsule_data[0][224 +: 96];
                rem_data_len  <= 'd0 ;
                payload_valid <= 'd1;
                dat_chk_dn    <= 'd1;
                seg_len       <= capsule_data[0][19:10];
                if(capsule_data[0][9:9]) // if CRC is present  
                    seg_len_cred      <= capsule_data[0][19:10] + 'd8;   //7 dw for header + 1 dw for crc
                else    
                    seg_len_cred      <= capsule_data[0][19:10] + 'd7;   //7 dw for header
            end 
            else            
            begin
                seg_len       <= 'd0;
                seg_len_cred  <= 'd0;
            end 
            if(capsule_data[1][8])                     //csi_has_payload if payload is available ,extracting payload
            begin 
                payload_s1       <= capsule_data[1][224 +: 96];
                rem_data_len_s1  <= (capsule_data[1][19:10] == 'd0)? 'd4093 :(capsule_data[1][19:10] - 'd3) ; //4096-3
                payload_valid_s1 <= 'd1;
                seg_len_s1       <= 'd3;
                dat_chk_dn_s1    <= 'd1;
            end 
            else            
            begin
                seg_len_s1       <= 'd0;
            end             
        end
        else
        begin
            dat_chk_st_o               <= 'd0;
            dat_chk_dn                 <= 'd0;
            payload_valid              <= 'd0;
            dat_chk_dn_s1              <= 'd0;
            payload_valid_s1           <= 'd0;
            check_p1_o                 <= 'd0;
            barrier_cap_detected_o       <= 'd0;
            iob_ctl_cap_detected_o       <= 'd0;
        end
        end
        st_eop_sop_eop_2pkts: begin
        if(capsule_valid == 'b11)
        begin       
 ////////// Fixed header extraction 48 bits
            cap_in_data_s1.hdr.csi_type                  <= csi_cap_type_t'(capsule_data[1][5:0]);
            cap_in_data_s1.hdr.csi_flow                  <= csi_flow_t'(capsule_data[1][7:6]);
            cap_in_data_s1.hdr.csi_has_payload           <= capsule_data[1][8:8];
            cap_in_data_s1.hdr.csi_has_payload_check     <= capsule_data[1][9:9];      // not required for data extraction 
            cap_in_data_s1.hdr.csi_dw_len                <= capsule_data[1][19:10];      //length pbtained in dword.1 dword = 32 bits
            cap_in_data_s1.hdr.src.info.csi_vc           <= capsule_data[1][23:20];    // only 0th VC used
            cap_in_data_s1.hdr.src.info.csi_src          <= capsule_data[1][28:24];
            cap_in_data_s1.hdr.src.csi_dst_fifo          <= capsule_data[1][28:20];
            cap_in_data_s1.hdr.csi_dst                   <= capsule_data[1][33:29];    // capsule already routed to destination ,not required
            cap_in_data_s1.hdr.pr.info.csi_rro           <= capsule_data[1][34:34];
            cap_in_data_s1.hdr.pr.info.csi_after_pr_seq  <= capsule_data[1][42:35];
            cap_in_data_s1.hdr.csi_poison                <= capsule_data[1][43];
            cap_in_data_s1.hdr.csi_is_managed            <= capsule_data[1][44];
            cap_in_data_s1.hdr.csi_reserved              <= 'd0;
            dat_chk_st_o                                 <= 'b10;
            dat_chk_dn                                   <= 'd1;
            rem_data_len                                 <= 'd0;  
            dat_chk_dn_s1                                <= 'd1;
            payload_valid_s1                             <= 'd0;
            rem_data_len_s1                              <= 'd0; 
            payload                                      <= capsule_data[0][319:0];
            payload_valid                                <= 'd1;
            check_p1_o                                   <= 'd1;
            barrier_cap_detected_o                         <= 'd0;
            if(previous_state == st_eop_sop_2pkts || previous_state == st_sop_eop_sop_2pkts)
            begin
                seg_len                                  <= rem_data_len_s1; 
                if(cap_in_data.hdr.csi_has_payload_check) // if CRC is present  
                    seg_len_cred                         <= rem_data_len_s1 + 'd1;   // +1 dw for crc
                else                                    
                    seg_len_cred                         <= rem_data_len_s1;
            end                                         
            else                                        
            begin                                       
                seg_len                                  <= rem_data_len ; 
                if(cap_in_data.hdr.csi_has_payload_check) // if CRC is present  
                    seg_len_cred                         <= rem_data_len + 'd1;   // +1 dw for crc
                else                                    
                    seg_len_cred                         <= rem_data_len;
            end        
            if(((csi_cap_type_t'(capsule_data[1][5:0])) == CSI_CT_IB_CTL ) ||
               ((csi_cap_type_t'(capsule_data[1][5:0])) == CSI_CT_OB_CTL ))
            begin
                iob_ctl_cap_detected_o                 <= 'd1;
            end 
            else
                iob_ctl_cap_detected_o                 <= 'd0;
 ////////// Variable header extraction 165 bits for segment 1
            case(capsule_data[1][5:0])
                CSI_CT_COMPLETION:begin
                    cap_in_data_s1.ptype.cmpl.attr                      <= capsule_data[1][50:48];
                    cap_in_data_s1.ptype.cmpl.completer                 <= capsule_data[1][66:51];
                    cap_in_data_s1.ptype.cmpl.requester                 <= capsule_data[1][82:67];
                    cap_in_data_s1.ptype.cmpl.request_type              <= csi_cap_type_t'(capsule_data[1][88:83]);
                    cap_in_data_s1.ptype.cmpl.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[1][90:89]);
                    cap_in_data_s1.ptype.cmpl.status                    <= csi_cpl_status_t'(capsule_data[1][93:91]);
                    cap_in_data_s1.ptype.cmpl.tc                        <= capsule_data[1][96:94];
                    cap_in_data_s1.ptype.cmpl.tag                       <= capsule_data[1][106:97];
                    cap_in_data_s1.ptype.cmpl.lower_addr                <= capsule_data[1][113:107];
                    cap_in_data_s1.ptype.cmpl.byte_count                <= capsule_data[1][126:114];
                    cap_in_data_s1.ptype.cmpl.is_first                  <= capsule_data[1][127];
                    cap_in_data_s1.ptype.cmpl.is_last                   <= capsule_data[1][128];
                    cap_in_data_s1.ptype.cmpl.rsv                       <= 'd0;
                    if((csi_cap_type_t'(capsule_data[1][88:83])) == CSI_CT_BARRIER)
                    begin
                        barrier_cap_detected_o[0]                         <= 'd1;
                    end
                    else
                        barrier_cap_detected_o[0]                         <= 'b0;                   
                end                                                   
                CSI_CT_RD_MEM,CSI_CT_SWAP,CSI_CT_CAS,CSI_CT_FETCHADD:begin                                         //NPR request
                    cap_in_data_s1.ptype.rw.attr                        <= capsule_data[1][50:48];
                    cap_in_data_s1.ptype.rw.requester                   <= capsule_data[1][66:51];
                    cap_in_data_s1.ptype.rw.completer                   <= capsule_data[1][82:67];
                    cap_in_data_s1.ptype.rw.completer_set               <= capsule_data[1][83];
                    cap_in_data_s1.ptype.rw.addr                        <= capsule_data[1][145:84];
                    cap_in_data_s1.ptype.rw.addr_type                   <= csi_pcie_addr_type_t'(capsule_data[1][147:146]);
                    cap_in_data_s1.ptype.rw.byte_enables                <= capsule_data[1][155:148];
                    cap_in_data_s1.ptype.rw.pasid                       <= capsule_data[1][178:156];                          
                    cap_in_data_s1.ptype.rw.tc                          <= capsule_data[1][181:179];                        
                    cap_in_data_s1.ptype.rw.tph                         <= capsule_data[1][192:182];
                    cap_in_data_s1.ptype.rw.tag                         <= capsule_data[1][202:193];
                    cap_in_data_s1.ptype.rw.secure                      <= capsule_data[1][203];
                    cap_in_data_s1.ptype.rw.trusted                     <= capsule_data[1][204];
                    cap_in_data_s1.ptype.rw.ide_enable                  <= capsule_data[1][205];
                    cap_in_data_s1.ptype.rw.rsv                         <= 'd0;
                end   
                CSI_CT_WR_MEM:begin                                       //PR request
                    cap_in_data_s1.ptype.rw.attr                   <= capsule_data[1][50:48];
                    cap_in_data_s1.ptype.rw.requester              <= capsule_data[1][66:51];
                    cap_in_data_s1.ptype.rw.completer              <= capsule_data[1][82:67];
                    cap_in_data_s1.ptype.rw.completer_set          <= capsule_data[1][83];
                    cap_in_data_s1.ptype.rw.addr                   <= capsule_data[1][145:84];
                    cap_in_data_s1.ptype.rw.addr_type              <= csi_pcie_addr_type_t'(capsule_data[1][147:146]);
                    cap_in_data_s1.ptype.rw.byte_enables           <= capsule_data[1][155:148];
                    cap_in_data_s1.ptype.rw.pasid                  <= capsule_data[1][178:156];                          
                    cap_in_data_s1.ptype.rw.tc                     <= capsule_data[1][181:179];                        
                    cap_in_data_s1.ptype.rw.tph                    <= capsule_data[1][192:182];
                    cap_in_data_s1.ptype.rw.tag                    <= capsule_data[1][202:193];
                    cap_in_data_s1.ptype.rw.secure                 <= capsule_data[1][203];
                    cap_in_data_s1.ptype.rw.trusted                <= capsule_data[1][204];
                    cap_in_data_s1.ptype.rw.ide_enable             <= capsule_data[1][205];
                    cap_in_data_s1.ptype.rw.rsv                    <= 'd0;
                end 
                CSI_CT_MESSAGE_RQ : begin                
                    

                    cap_in_data.ptype.msg.attr                      <= capsule_data[1][50:48];
                    cap_in_data.ptype.msg.requester                 <= capsule_data[1][66:51];;
                    cap_in_data.ptype.msg.msg_cookie                <= csi_msg_cookie_t'(capsule_data[1][74:67]);
                    cap_in_data.ptype.msg.secure                    <= capsule_data[1][75];
                    cap_in_data.ptype.msg.trusted                   <= capsule_data[1][76];
                    cap_in_data.ptype.msg.ide_enable                <= capsule_data[1][77];
                    cap_in_data.ptype.msg.msg_tlp_hdr.fmt   <= capsule_data[1][205:203];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ptype   <= capsule_data[1][202:198];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t9   <= capsule_data[1][197];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tc  <= capsule_data[1][196:194];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t8  <= capsule_data[1][193];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr2  <= capsule_data[1][192];
                    cap_in_data.ptype.msg.msg_tlp_hdr.rsvd  <= capsule_data[1][191];
                    cap_in_data.ptype.msg.msg_tlp_hdr.th <= capsule_data[1][190];
                    cap_in_data.ptype.msg.msg_tlp_hdr.td  <= capsule_data[1][189];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ep  <= capsule_data[1][188];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr1_0  <= capsule_data[1][187:186];
                    cap_in_data.ptype.msg.msg_tlp_hdr.at  <= capsule_data[1][185:184];
                    cap_in_data.ptype.msg.msg_tlp_hdr.length  <= capsule_data[1][183:174];
                    cap_in_data.ptype.msg.msg_tlp_hdr.requester_id  <= capsule_data[1][173:158];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tag  <= capsule_data[1][157:150];
                   // cap_in_data.ptype.msg.msg_tlp_hdr <= csi_msg_tlp_hdr_t' (capsule_data[1][205:86]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.message_code  <= csi_pcie_message_code_t'(capsule_data[1][149:142]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.destination_id  <= capsule_data[1][141:126];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.vendor_id  <= capsule_data[1][125:110];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.subtype  <= capsule_data[1][109:102];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.pci_sig_vdm_bytes  <= capsule_data[1][101:78];
                    cap_in_data.ptype.msg.rsv                       <= 7'd0;

                    
                end   

            endcase
 ////////// ECC Valid 1 bit
 ////////// ECC Value 10 bits
            

            if(capsule_data[1][8])                     //csi_has_payload if payload is available ,extracting payload
            begin 
                payload_s1       <= capsule_data[1][224 +: 96];
                payload_valid_s1 <= 'd1;
                seg_len_s1       <= capsule_data[1][19:10];     //dw_len
            end 
            else            
            begin
                seg_len_s1       <= 'd0;
            end             
        end
        else
        begin
            dat_chk_st_o               <= 'd0;
            dat_chk_dn                 <= 'd0;
            payload_valid              <= 'd0;
            dat_chk_dn_s1              <= 'd0;
            payload_valid_s1           <= 'd0;
            barrier_cap_detected_o       <= 'd0;
            iob_ctl_cap_detected_o       <= 'd0;
        end
        end
        st_eop_sop_2pkts: begin
        if(capsule_valid == 'b11)
        begin       
 ////////// Fixed header extraction 48 bits
            cap_in_data_s1.hdr.csi_type                  <= csi_cap_type_t'(capsule_data[1][5:0]);
            cap_in_data_s1.hdr.csi_flow                  <= csi_flow_t'(capsule_data[1][7:6]);
            cap_in_data_s1.hdr.csi_has_payload           <= capsule_data[1][8:8];
            cap_in_data_s1.hdr.csi_has_payload_check     <= capsule_data[1][9:9];      // not required for data extraction 
            cap_in_data_s1.hdr.csi_dw_len                <= capsule_data[1][19:10];      //length pbtained in dword.1 dword = 32 bits
            cap_in_data_s1.hdr.src.info.csi_vc           <= capsule_data[1][23:20];    // only 0th VC used
            cap_in_data_s1.hdr.src.info.csi_src          <= capsule_data[1][28:24];
            cap_in_data_s1.hdr.src.csi_dst_fifo          <= capsule_data[1][28:20];
            cap_in_data_s1.hdr.csi_dst                   <= capsule_data[1][33:29];    // capsule already routed to destination ,not required
            cap_in_data_s1.hdr.pr.info.csi_rro           <= capsule_data[1][34:34];
            cap_in_data_s1.hdr.pr.info.csi_after_pr_seq  <= capsule_data[1][42:35];
            cap_in_data_s1.hdr.csi_poison                <= capsule_data[1][43];
            cap_in_data_s1.hdr.csi_is_managed            <= capsule_data[1][44];
            cap_in_data_s1.hdr.csi_reserved              <= 'd0;
            dat_chk_st_o                                 <= 'b10;
            dat_chk_dn                                   <= 'd1;
            rem_data_len                                 <= 'd0; 
            dat_chk_dn_s1                                <= 'd0;
            payload_valid_s1                             <= 'd0;
            rem_data_len_s1                              <= 'd0; 
            payload                                      <= capsule_data[0][319:0];
            payload_valid                                <= 'd1;
            check_p1_o                                   <= 'd1;
            barrier_cap_detected_o                         <= 'd0;
            if(((csi_cap_type_t'(capsule_data[1][5:0])) == CSI_CT_IB_CTL ) ||
               ((csi_cap_type_t'(capsule_data[1][5:0])) == CSI_CT_OB_CTL ))
            begin
                iob_ctl_cap_detected_o                 <= 'd1;
            end 
            else
                iob_ctl_cap_detected_o                 <= 'd0;
            if(previous_state == st_eop_sop_2pkts || previous_state == st_sop_eop_sop_2pkts)
            begin
                seg_len                                  <= rem_data_len_s1; 
                if(cap_in_data.hdr.csi_has_payload_check) // if CRC is present  
                    seg_len_cred                         <= rem_data_len_s1 + 'd1;   // +1 dw for crc
                else                                    
                    seg_len_cred                         <= rem_data_len_s1;
            end                                         
            else                                        
            begin                                       
                seg_len                                  <= rem_data_len ;
                if(cap_in_data.hdr.csi_has_payload_check) // if CRC is present  
                    seg_len_cred                         <= rem_data_len + 'd1;   // +1 dw for crc
                else                                    
                    seg_len_cred                         <= rem_data_len;
            end   
            
 ////////// Variable header extraction 165 bits for segment 1
            case(capsule_data[1][5:0])
                CSI_CT_COMPLETION:begin
                    cap_in_data_s1.ptype.cmpl.attr                      <= capsule_data[1][50:48];
                    cap_in_data_s1.ptype.cmpl.completer                 <= capsule_data[1][66:51];
                    cap_in_data_s1.ptype.cmpl.requester                 <= capsule_data[1][82:67];
                    cap_in_data_s1.ptype.cmpl.request_type              <= csi_cap_type_t'(capsule_data[1][88:83]);
                    cap_in_data_s1.ptype.cmpl.addr_type                 <= csi_pcie_addr_type_t'(capsule_data[1][90:89]);
                    cap_in_data_s1.ptype.cmpl.status                    <= csi_cpl_status_t'(capsule_data[1][93:91]);
                    cap_in_data_s1.ptype.cmpl.tc                        <= capsule_data[1][96:94];
                    cap_in_data_s1.ptype.cmpl.tag                       <= capsule_data[1][106:97];
                    cap_in_data_s1.ptype.cmpl.lower_addr                <= capsule_data[1][113:107];
                    cap_in_data_s1.ptype.cmpl.byte_count                <= capsule_data[1][126:114];
                    cap_in_data_s1.ptype.cmpl.is_first                  <= capsule_data[1][127];
                    cap_in_data_s1.ptype.cmpl.is_last                   <= capsule_data[1][128];
                    cap_in_data_s1.ptype.cmpl.rsv                       <= 'd0;
                    if((csi_cap_type_t'(capsule_data[1][88:83])) == CSI_CT_BARRIER)
                    begin
                        barrier_cap_detected_o[0]                         <= 'b1;
                    end 
                    else
                        barrier_cap_detected_o[0]                         <= 'b0;
                end  
                CSI_CT_RD_MEM,CSI_CT_SWAP,CSI_CT_CAS,CSI_CT_FETCHADD:begin                                       //NPR request
                    cap_in_data_s1.ptype.rw.attr                        <= capsule_data[1][50:48];
                    cap_in_data_s1.ptype.rw.requester                   <= capsule_data[1][66:51];
                    cap_in_data_s1.ptype.rw.completer                   <= capsule_data[1][82:67];
                    cap_in_data_s1.ptype.rw.completer_set               <= capsule_data[1][83];
                    cap_in_data_s1.ptype.rw.addr                        <= capsule_data[1][145:84];
                    cap_in_data_s1.ptype.rw.addr_type                   <= csi_pcie_addr_type_t'(capsule_data[1][147:146]);
                    cap_in_data_s1.ptype.rw.byte_enables                <= capsule_data[1][155:148];
                    cap_in_data_s1.ptype.rw.pasid                       <= capsule_data[1][178:156];                          
                    cap_in_data_s1.ptype.rw.tc                          <= capsule_data[1][181:179];                        
                    cap_in_data_s1.ptype.rw.tph                         <= capsule_data[1][192:182];
                    cap_in_data_s1.ptype.rw.tag                         <= capsule_data[1][202:193];
                    cap_in_data_s1.ptype.rw.secure                      <= capsule_data[1][203];
                    cap_in_data_s1.ptype.rw.trusted                     <= capsule_data[1][204];
                    cap_in_data_s1.ptype.rw.ide_enable                  <= capsule_data[1][205];
                    cap_in_data_s1.ptype.rw.rsv                         <= 'd0;
                end   
                CSI_CT_WR_MEM:begin                                       //PR request
                    cap_in_data_s1.ptype.rw.attr                   <= capsule_data[1][50:48];
                    cap_in_data_s1.ptype.rw.requester              <= capsule_data[1][66:51];
                    cap_in_data_s1.ptype.rw.completer              <= capsule_data[1][82:67];
                    cap_in_data_s1.ptype.rw.completer_set          <= capsule_data[1][83];
                    cap_in_data_s1.ptype.rw.addr                   <= capsule_data[1][145:84];
                    cap_in_data_s1.ptype.rw.addr_type              <= csi_pcie_addr_type_t'(capsule_data[1][147:146]);
                    cap_in_data_s1.ptype.rw.byte_enables           <= capsule_data[1][155:148];
                    cap_in_data_s1.ptype.rw.pasid                  <= capsule_data[1][178:156];                          
                    cap_in_data_s1.ptype.rw.tc                     <= capsule_data[1][181:179];                        
                    cap_in_data_s1.ptype.rw.tph                    <= capsule_data[1][192:182];
                    cap_in_data_s1.ptype.rw.tag                    <= capsule_data[1][202:193];
                    cap_in_data_s1.ptype.rw.secure                 <= capsule_data[1][203];
                    cap_in_data_s1.ptype.rw.trusted                <= capsule_data[1][204];
                    cap_in_data_s1.ptype.rw.ide_enable             <= capsule_data[1][205];
                    cap_in_data_s1.ptype.rw.rsv                    <= 'd0;
                end 

                CSI_CT_MESSAGE_RQ : begin                
                    

                    cap_in_data.ptype.msg.attr                      <= capsule_data[1][50:48];
                    cap_in_data.ptype.msg.requester                 <= capsule_data[1][66:51];;
                    cap_in_data.ptype.msg.msg_cookie                <= csi_msg_cookie_t'(capsule_data[1][74:67]);
                    cap_in_data.ptype.msg.secure                    <= capsule_data[1][75];
                    cap_in_data.ptype.msg.trusted                   <= capsule_data[1][76];
                    cap_in_data.ptype.msg.ide_enable                <= capsule_data[1][77];
                    cap_in_data.ptype.msg.msg_tlp_hdr.fmt   <= capsule_data[1][205:203];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ptype   <= capsule_data[1][202:198];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t9   <= capsule_data[1][197];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tc  <= capsule_data[1][196:194];
                    cap_in_data.ptype.msg.msg_tlp_hdr.t8  <= capsule_data[1][193];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr2  <= capsule_data[1][192];
                    cap_in_data.ptype.msg.msg_tlp_hdr.rsvd  <= capsule_data[1][191];
                    cap_in_data.ptype.msg.msg_tlp_hdr.th <= capsule_data[1][190];
                    cap_in_data.ptype.msg.msg_tlp_hdr.td  <= capsule_data[1][189];
                    cap_in_data.ptype.msg.msg_tlp_hdr.ep  <= capsule_data[1][188];
                    cap_in_data.ptype.msg.msg_tlp_hdr.attr1_0  <= capsule_data[1][187:186];
                    cap_in_data.ptype.msg.msg_tlp_hdr.at  <= capsule_data[1][185:184];
                    cap_in_data.ptype.msg.msg_tlp_hdr.length  <= capsule_data[1][183:174];
                    cap_in_data.ptype.msg.msg_tlp_hdr.requester_id  <= capsule_data[1][173:158];
                    cap_in_data.ptype.msg.msg_tlp_hdr.tag  <= capsule_data[1][157:150];
                   // cap_in_data.ptype.msg.msg_tlp_hdr <= csi_msg_tlp_hdr_t' (capsule_data[1][205:86]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.message_code  <= csi_pcie_message_code_t'(capsule_data[1][149:142]);
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.destination_id  <= capsule_data[1][141:126];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.vendor_id  <= capsule_data[1][125:110];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.subtype  <= capsule_data[1][109:102];
                    cap_in_data.ptype.msg.msg_tlp_hdr.mtype.pci_sig_vdm.pci_sig_vdm_bytes  <= capsule_data[1][101:78];
                    cap_in_data.ptype.msg.rsv                       <= 7'd0;

                end   
            endcase
 ////////// ECC Valid 1 bit
 ////////// ECC Value 10 bits
    
            if(capsule_data[1][8])                     //csi_has_payload if payload is available ,extracting payload
            begin 
                payload_s1       <= capsule_data[1][224 +: 96];
                rem_data_len_s1  <= (capsule_data[1][19:10] == 'd0)? 'd4093 :(capsule_data[1][19:10] - 'd3) ; //4096-3
                payload_valid_s1 <= 'd1;
                seg_len_s1       <= 'd3;
            end    
            else            
            begin
                seg_len_s1       <= 'd0;
            end             
        end
        else
        begin
            dat_chk_st_o               <= 'd0;
            dat_chk_dn                 <= 'd0;
            payload_valid              <= 'd0;
            dat_chk_dn_s1              <= 'd0;
            payload_valid_s1           <= 'd0;
            check_p1_o                 <= 'd0;
            barrier_cap_detected_o       <= 'd0;
            iob_ctl_cap_detected_o       <= 'd0;
        end
        end
        default:
        begin
            dat_chk_st_o              <= 'd0;
            dat_chk_dn                <= 'd0;
            payload_valid             <= 'd0;
            dat_chk_dn_s1             <= 'd0;
            payload_valid_s1          <= 'd0;
            check_p1_o                <= 'd0;
            barrier_cap_detected_o      <= 'd0;
            iob_ctl_cap_detected_o      <= 'd0;
        end
      endcase  
   end
end

always_ff @(posedge clk)
begin
    if(!rst_n)
    begin
        pr_data_o        <= 'd0;
        pr_data_p1_o     <= 'd0;
        pr_req_o         <= 'd0;
        cmpl_data_o      <= 'd0;
        cmpl_data_p1_o   <= 'd0;
        cmpl_req_o       <= 'd0;
        dat_chk_dn_o     <= 'd0;
        seg_len_o        <= 'd0;
        dat_chk_st_d     <= 'd0;
        seg_len_cred_d   <= 'd0;
        crdts_vld        <= 'd0;
    end
    else
    begin 
        dat_chk_dn_o     <= {dat_chk_dn_s1,dat_chk_dn};
        seg_len_o        <= {seg_len_s1,seg_len};
        crdts_vld        <= dat_chk_dn_o;
        dat_chk_st_d     <= dat_chk_st_o;
        seg_len_cred_d   <= seg_len_cred;  
        if (payload_valid && payload_valid_s1)
        begin
            if(csi_flow_o[1:0] == 'd2 && csi_flow_o[3:2] == 'd2)                //PR received
            begin
                pr_data_p1_o   <= payload_s1;
                pr_data_o      <= payload;
                pr_req_o       <= 2'b11;
            end
            else if(csi_flow_o[1:0] == 'd1 && csi_flow_o[3:2] == 'd1)           //CMPL received
            begin
                cmpl_data_p1_o <= payload_s1;
                cmpl_data_o    <= payload;
                cmpl_req_o     <= 2'b11;
            end
            else if(csi_flow_o[1:0] == 'd2 && csi_flow_o[3:2] == 'd1)                //PR received
            begin
                cmpl_data_o      <= payload_s1;
                pr_data_o        <= payload;
                pr_req_o         <= 2'b01;
                cmpl_req_o       <= 2'b01;
            end
            else if(csi_flow_o[1:0] == 'd1 && csi_flow_o[3:2] == 'd2)           //CMPL received
            begin
                cmpl_data_o      <= payload;
                pr_data_o        <= payload_s1;
                pr_req_o         <= 2'b01;
                cmpl_req_o       <= 2'b01;
            end
            else if(csi_flow_o[1:0] == 'd2)                //PR received
            begin
                pr_data_o        <= payload;
                pr_req_o         <= 2'b01;
                cmpl_req_o       <= 2'b00;
            end
            else if(csi_flow_o[1:0] == 'd1 )           //CMPL received
            begin
                cmpl_data_o      <= payload;
                pr_req_o         <= 2'b00;
                cmpl_req_o       <= 2'b01;
            end
            else if(csi_flow_o[3:2] == 'd1)           //CMPL received
            begin
                cmpl_data_o      <= payload_s1;
                pr_req_o         <= 2'b00;
                cmpl_req_o       <= 2'b01;
            end
            else if(csi_flow_o[3:2] == 'd2)           //CMPL received
            begin
                pr_data_o        <= payload_s1;
                pr_req_o         <= 2'b01;
                cmpl_req_o       <= 2'b00;
            end
            else
            begin
                pr_req_o       <= 2'b00;
                cmpl_req_o     <= 2'b00;            
            end
        end
        else if (payload_valid)
        begin
            if(csi_flow_o[1:0] == 2)                //PR received
            begin
                pr_data_o  <= payload;
                pr_req_o   <= 2'b01;
                cmpl_req_o <= 2'b00;
            end
            else if(csi_flow_o[1:0] == 1)           //CMPL received
            begin
                cmpl_data_o <= payload;
                cmpl_req_o  <= 2'b01;
                pr_req_o    <= 2'b00;
            end
            else
            begin
                pr_req_o   <= 2'b00;
                cmpl_req_o <= 2'b00;            
            end
        end
        else
        begin
            pr_req_o       <= 2'b00;
            cmpl_req_o     <= 2'b00;            
        end
    end    
end


always @(posedge clk)
begin
    if(!rst_n) // go to state idle if reset
    begin
        cmpl_control_ram_we_o <= 'd0;
        cmpl_control_ram_we_d <= 'd0;
        cmpl_control_ram_we_d1 <= 'd0;
        cmpl_control_ram_we_d2 <= 'd0;
        cmpl_control_ram_data_o <= 'd0;
        cmpl_control_ram_data_ready <= 'b0;
        count_cntrl_cap             <= 'd0;
        npr_iob_ctl_cap_detected    <= 'd0; 
    end
    else // otherwise update the states
    begin
        cmpl_control_ram_we_d  <= cmpl_control_ram_we_o;
        cmpl_control_ram_we_d1 <= cmpl_control_ram_we_d;
        cmpl_control_ram_we_d2 <= cmpl_control_ram_we_d1;
        cmpl_control_ram_data_ready <= cmpl_control_ram_we_d2;
        if(capsule_valid_d == 2'b11 && csi_flow_o[1:0] == 0 && csi_flow_o[3:2] == 0)    
         begin
            ///src extracted from NPR will be positioned at csi_dst and vice versa for completion
             cmpl_control_ram_data_o <= {26'd0,1'b0/*second_pkt_present*/,cap_in_data_s1.hdr.csi_type,cap_in_data_s1.hdr.csi_dw_len,1'b1/*is_last*/,{cap_in_data_s1.hdr.csi_dw_len,2'b00}/*byte_count*/,
                                         1'b1/*is_first*/,{cap_in_data_s1.ptype.rw.addr[4:0],2'b00}/*lower_addr*/,cap_in_data_s1.ptype.rw.tag,cap_in_data_s1.ptype.rw.tc,
                                         cap_in_data_s1.ptype.rw.attr,cap_in_data_s1.hdr.csi_poison,cap_in_data_s1.hdr.csi_is_managed,cap_in_data_s1.hdr.src.info.csi_src,
                                         cap_in_data_s1.hdr.csi_dst,cap_in_data_s1.hdr.src.info.csi_vc,cap_in_data_s1.ptype.rw.completer/*completer*/,cap_in_data_s1.ptype.rw.requester/*requester*/,
                                         26'd0,1'b1/*second_pkt_present*/,cap_in_data_s1.hdr.csi_type,cap_in_data.hdr.csi_dw_len,1'b1/*is_last*/,{cap_in_data.hdr.csi_dw_len,2'b00}/*byte_count*/,
                                         1'b1/*is_first*/,{cap_in_data.ptype.rw.addr[4:0],2'b00}/*lower_addr*/,cap_in_data.ptype.rw.tag,cap_in_data.ptype.rw.tc,
                                         cap_in_data.ptype.rw.attr,cap_in_data.hdr.csi_poison,cap_in_data.hdr.csi_is_managed,cap_in_data.hdr.src.info.csi_src,
                                         cap_in_data.hdr.csi_dst,cap_in_data.hdr.src.info.csi_vc,cap_in_data.ptype.rw.completer/*completer*/,cap_in_data.ptype.rw.requester/*requester*/};
             if((cap_in_data_s1.hdr.csi_type == CSI_CT_IB_CTL || cap_in_data_s1.hdr.csi_type == CSI_CT_OB_CTL) &&
                (cap_in_data.hdr.csi_type == CSI_CT_IB_CTL || cap_in_data.hdr.csi_type == CSI_CT_OB_CTL))
             begin
                count_cntrl_cap             <= count_cntrl_cap + 'd2;
                cmpl_control_ram_we_o       <= 1'b0;
                npr_iob_ctl_cap_detected    <= 'b1; 
             end
             else if((cap_in_data_s1.hdr.csi_type == CSI_CT_IB_CTL || cap_in_data_s1.hdr.csi_type == CSI_CT_OB_CTL) ||
                (cap_in_data.hdr.csi_type == CSI_CT_IB_CTL || cap_in_data.hdr.csi_type == CSI_CT_OB_CTL))
             begin
                count_cntrl_cap             <= count_cntrl_cap + 'd1;
                cmpl_control_ram_we_o       <= 1'b0;
                npr_iob_ctl_cap_detected    <= 'b1; 
             end
             else
             begin
                cmpl_control_ram_we_o       <= 1'b1;
                npr_iob_ctl_cap_detected    <= 'b0; 
             end
         end
         else if(capsule_valid_d[0] && csi_flow_o[1:0] == 0)    
         begin
            ///src extracted from NPR will be positioned at csi_dst and vice versa for completion
             cmpl_control_ram_data_o <= {'d0,cap_in_data.hdr.csi_type,cap_in_data.hdr.csi_dw_len,1'b1/*is_last*/,{cap_in_data.hdr.csi_dw_len,2'b00}/*byte_count*/,
                                         1'b1/*is_first*/,{cap_in_data.ptype.rw.addr[4:0],2'b00}/*lower_addr*/,cap_in_data.ptype.rw.tag,cap_in_data.ptype.rw.tc,
                                         cap_in_data.ptype.rw.attr,cap_in_data.hdr.csi_poison,cap_in_data.hdr.csi_is_managed,cap_in_data.hdr.src.info.csi_src,
                                         cap_in_data.hdr.csi_dst,cap_in_data.hdr.src.info.csi_vc,cap_in_data.ptype.rw.completer/*completer*/,cap_in_data.ptype.rw.requester/*requester*/};
             if(cap_in_data.hdr.csi_type == CSI_CT_IB_CTL || cap_in_data.hdr.csi_type == CSI_CT_OB_CTL)
             begin
                count_cntrl_cap             <= count_cntrl_cap + 'd1;
                cmpl_control_ram_we_o       <= 1'b0;
                npr_iob_ctl_cap_detected    <= 'b1; 
             end
             else
             begin
                cmpl_control_ram_we_o       <= 1'b1;
                npr_iob_ctl_cap_detected    <= 'b0; 
             end             
         end
         else if(capsule_valid_d[1] && (csi_flow_o[3:2]  == 0) && capsule_start_d[1])    
         begin
            ///src extracted from NPR will be positioned at csi_dst and vice versa for completion
             cmpl_control_ram_data_o <= {'d0,cap_in_data_s1.hdr.csi_type,cap_in_data_s1.hdr.csi_dw_len,1'b1/*is_last*/,{cap_in_data_s1.hdr.csi_dw_len,2'b00}/*byte_count*/,
                                         1'b1/*is_first*/,{cap_in_data_s1.ptype.rw.addr[4:0],2'b00}/*lower_addr*/,cap_in_data_s1.ptype.rw.tag,cap_in_data_s1.ptype.rw.tc,
                                         cap_in_data_s1.ptype.rw.attr,cap_in_data_s1.hdr.csi_poison,cap_in_data_s1.hdr.csi_is_managed,cap_in_data_s1.hdr.src.info.csi_src,
                                         cap_in_data_s1.hdr.csi_dst,cap_in_data_s1.hdr.src.info.csi_vc,cap_in_data_s1.ptype.rw.completer/*completer*/,cap_in_data_s1.ptype.rw.requester/*requester*/};
             if(cap_in_data_s1.hdr.csi_type == CSI_CT_IB_CTL || cap_in_data_s1.hdr.csi_type == CSI_CT_OB_CTL)
             begin
                count_cntrl_cap             <= count_cntrl_cap + 'd1;
                cmpl_control_ram_we_o       <= 1'b0;
                npr_iob_ctl_cap_detected    <= 'b1; 
             end
             else
             begin
                cmpl_control_ram_we_o       <= 1'b1;
                npr_iob_ctl_cap_detected    <= 'b0; 
             end
         end
         else
         begin
             cmpl_control_ram_we_o       <= 1'b0;   
             npr_iob_ctl_cap_detected    <= 'b0;
         end            
     end
end

/////////////////////////////////////Barrier_capsule_count///////////////////
always @(posedge clk)
begin
    if(!rst_n)
    begin
        count_barrier_cap           <= 'd0;
        count_iob_ctl_cap           <= 'd0;
        barrier_cap_detected_d      <= 'd0;
        iob_ctl_cap_detected_d      <= 'd0;
    end
    else
    begin
        barrier_cap_detected_d      <= barrier_cap_detected_o;
        iob_ctl_cap_detected_d      <= iob_ctl_cap_detected_o;
        if(barrier_cap_detected_o == 'b11)
        begin
            count_barrier_cap      <= count_barrier_cap + 'd2;
        end
        else if(barrier_cap_detected_o == 'd1)
        begin
            count_barrier_cap      <= count_barrier_cap + 'd1;
        end
        if(iob_ctl_cap_detected_o == 'b11)
        begin
            count_iob_ctl_cap      <= count_iob_ctl_cap + 'd2;
        end     
        else if(iob_ctl_cap_detected_o == 'd1)
        begin
            count_iob_ctl_cap      <= count_iob_ctl_cap + 'd1;
        end     
    end
end


/////////////////////////////////////////////////////////////////////////////
//                                  Assignments                            //
////////////////////////////////////////////////////////////////////////////

assign csi_flow_o = {cap_in_data_s1.hdr.csi_flow,cap_in_data.hdr.csi_flow};
assign dat_chk_st_d_o = dat_chk_st_d;

endmodule

