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
`include "cdx5n_defines.svh"
`include "cdx5n_csi_defines.svh"

module uport_counters 
#(
  parameter  TCQ                   = 0
)(
        // Ports 
        // Clocks / Resets
        input                          clk,
        input                          rst_n,
        input                          data_chk_pass_i,
        input                          data_chk_err_i,
        input  [1:0]                   data_chk_dn_i,
        input  [1:0]                   data_chk_st_i,
             
        //cdx5n_fab_2s_seg_if.in         csi2f_port0_i,
        input                          capsule_valid_i,
        input [1:0]                    flow_type_i,
        input [9:0]                    csi_dw_len_i,
        input                          sop_i,
        
        input                          data_chk_pass_p1_i , 
        input                          data_chk_err_p1_i  , 
        input                          capsule_valid_p1_i , 
        input [1:0]                    flow_type_p1_i     ,
        input [1:0]                    barrier_cap_detected_i,
        input [1:0]                    iob_ctl_cap_detected_i,      
        
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
  input m_aximm00_awready_i,
  
  (* mark_debug = "true" *) output logic [31:0] m_aximm00_awvalid_cnt_o,    //TG awvalid count
  (* mark_debug = "true" *) output logic [31:0] m_aximm00_arvalid_cnt_o,   
  (* mark_debug = "true" *) output logic [31:0] m_aximm00_wlast_cnt_o,    
  (* mark_debug = "true" *) output logic [31:0] m_aximm00_wvalid_cnt_o,    
  (* mark_debug = "true" *) output logic [31:0] m_aximm00_rlast_cnt_o,    
  (* mark_debug = "true" *) output logic [31:0] m_aximm00_rvalid_cnt_o,
  (* mark_debug = "true" *) output logic [31:0] m_aximm00_arready_cnt_o,
  (* mark_debug = "true" *) output logic [31:0] m_aximm00_awready_cnt_o,


  (* mark_debug = "true" *) output logic [31:0] s_aximm00_awvalid_cnt_o,    //TG awvalid count
  (* mark_debug = "true" *) output logic [31:0] s_aximm00_arvalid_cnt_o,   
  (* mark_debug = "true" *) output logic [31:0] s_aximm00_wlast_cnt_o,    
  (* mark_debug = "true" *) output logic [31:0] s_aximm00_wvalid_cnt_o,    
  (* mark_debug = "true" *) output logic [31:0] s_aximm00_rlast_cnt_o,    
  (* mark_debug = "true" *) output logic [31:0] s_aximm00_rvalid_cnt_o,
  
  
  (* mark_debug = "true" *) output reg  [31:0]             cmpl_pass_count_o,
  (* mark_debug = "true" *) output reg  [31:0]             pr_pass_count_o,
  (* mark_debug = "true" *) output reg  [31:0]             npr_pass_count_o,
  (* mark_debug = "true" *) output reg  [31:0]             cmpl_err_count_o,
  (* mark_debug = "true" *) output reg  [31:0]             pr_err_count_o,
  (* mark_debug = "true" *) output reg  [31:0]             npr_err_count_o
);
        
logic m_aximm00_rvalid_s1, s_aximm00_rvalid_s1; 
logic m_aximm00_wvalid_s1, s_aximm00_wvalid_s1;
logic m_aximm00_awvalid_s1, m_aximm00_awvalid_pulse;
logic m_aximm00_wlast_s1, s_aximm00_wlast_s1;
logic m_aximm00_rlast_s1, s_aximm00_rlast_s1;

logic m_aximm00_rvalid_pulse, s_aximm00_rvalid_pulse;
logic m_aximm00_wvalid_pulse, s_aximm00_wvalid_pulse;
logic m_aximm00_wlast_pulse, s_aximm00_wlast_pulse;
logic m_aximm00_rlast_pulse, s_aximm00_rlast_pulse;
    
logic inc_pr_err_count, inc_pr_pass_count;
logic inc_npr_err_count, inc_npr_pass_count;
logic inc_cmpl_err_count, inc_cmpl_pass_count;
logic capsule_valid_s1, capsule_valid_s2, capsule_valid_s3, capsule_valid_s4, capsule_valid_s5, capsule_valid_s6;
logic [1:0] data_chk_dn, data_chk_dn_r;
logic [1:0] data_chk_dn_cmpl,data_chk_dn_cmpl_r,data_chk_dn_cmpl_r1;
logic [1:0] data_chk_dn_pr, data_chk_dn_pr_r, data_chk_dn_pr_r1;
logic [5:0] chk_dn_count;
logic [5:0] chk_dn_count_pr, chk_dn_count_pr_s1;
logic [5:0] chk_dn_count_cmpl, chk_dn_count_cmpl_s1;
logic [1:0] flow_type_s1;
logic [1:0] flow_type_s2;
logic [1:0] flow_type_s3;
logic [1:0] flow_type_s4;
logic [1:0] flow_type_snapshot;
logic [1:0] flow_type_snapshot_s1;
logic [31:0] num_data_chk_err, num_data_chk_pass;
logic [31:0] num_data_chk_err_snapshot, num_data_chk_pass_snapshot;

logic [1:0] iob_ctl_cap_detected;
logic [1:0] barrier_cap_detected;

logic inc_pr_err_count_p1  , inc_pr_pass_count_p1  ;
logic inc_npr_err_count_p1 , inc_npr_pass_count_p1 ;
logic inc_cmpl_err_count_p1, inc_cmpl_pass_count_p1;
logic capsule_valid_p1_s1, capsule_valid_p1_s2, capsule_valid_p1_s3, capsule_valid_p1_s4, capsule_valid_p1_s5, capsule_valid_p1_s6;
logic [5:0] chk_dn_count_p1;
logic [5:0] chk_dn_count_p1_pr, chk_dn_count_p1_pr_s1;
logic [5:0] chk_dn_count_p1_cmpl, chk_dn_count_p1_cmpl_s1;
logic [1:0] flow_type_p1_s1;
logic [1:0] flow_type_p1_s2;
logic [1:0] flow_type_p1_s3;
logic [1:0] flow_type_p1_s4;
logic [1:0] flow_type_snapshot_p1;
logic [1:0] flow_type_snapshot_p1_s1;
logic [31:0] num_data_chk_err_p1, num_data_chk_pass_p1;
logic [31:0] num_data_chk_err_snapshot_p1, num_data_chk_pass_snapshot_p1;

logic [9:0] csi_dw_len;
logic [9:0] csi_dw_len_s1;
logic [9:0] csi_dw_len_s2;
logic [9:0] csi_dw_len_s3;
logic [9:0] csi_dw_len_s4;

logic data_chk_pass_s1, data_chk_err_s1;



`XSRREG_AXIMM(clk, rst_n, iob_ctl_cap_detected, iob_ctl_cap_detected_i, 1'b0)
`XSRREG_AXIMM(clk, rst_n, barrier_cap_detected, barrier_cap_detected_i, 1'b0)

`XSRREG_AXIMM(clk, rst_n, flow_type_s1, flow_type_i, 1'b0)
`XSRREG_AXIMM(clk, rst_n, flow_type_p1_s1, flow_type_p1_i, 1'b0)
`XSRREG_AXIMM(clk, rst_n, flow_type_s2, flow_type_s1, 1'b0)
`XSRREG_AXIMM(clk, rst_n, flow_type_p1_s2, flow_type_p1_s1, 1'b0)
`XSRREG_AXIMM(clk, rst_n, flow_type_s3, flow_type_s2, 1'b0)
`XSRREG_AXIMM(clk, rst_n, flow_type_p1_s3, flow_type_p1_s2, 1'b0)
`XSRREG_AXIMM(clk, rst_n, flow_type_s4, flow_type_s3, 1'b0)
`XSRREG_AXIMM(clk, rst_n, flow_type_p1_s4, flow_type_p1_s3, 1'b0)
assign data_chk_dn_r = 'd0;
assign chk_dn_count = 'd0;
assign chk_dn_count_p1 = 'd0;

`XSRREG_AXIMM(clk, rst_n, chk_dn_count_pr_s1, chk_dn_count_pr, 1'b0)
`XSRREG_AXIMM(clk, rst_n, chk_dn_count_cmpl_s1, chk_dn_count_cmpl, 1'b0)

`XSRREG_AXIMM(clk, rst_n, chk_dn_count_p1_pr_s1, chk_dn_count_p1_pr, 1'b0)
`XSRREG_AXIMM(clk, rst_n, chk_dn_count_p1_cmpl_s1, chk_dn_count_p1_cmpl, 1'b0)
/*
always @(posedge clk)
begin
    if(!rst_n) begin
        data_chk_dn <= 'b0;
        data_chk_dn_r <= 'b0;
    end
    else if (flow_type_s2 != 'd0) begin
        data_chk_dn     <= data_chk_dn_i;
        data_chk_dn_r   <= data_chk_dn;
    end
    else begin
        data_chk_dn <= 'b0;
        data_chk_dn_r <= 'b0;
    end
end
*/
always @(posedge clk)
begin
    if(!rst_n) begin
        data_chk_dn_pr_r <= 'b0;
        data_chk_dn_pr_r1 <= 'b0;
        data_chk_dn_cmpl_r <= 'b0;
        data_chk_dn_cmpl_r1 <= 'b0;
    end
    else begin
        data_chk_dn_pr_r     <= data_chk_dn_pr;
        data_chk_dn_pr_r1    <= data_chk_dn_pr_r;
        data_chk_dn_cmpl_r   <= data_chk_dn_cmpl;
        data_chk_dn_cmpl_r1  <= data_chk_dn_cmpl_r;
    end
end

always @(posedge clk)
begin
    if(!rst_n) begin
        data_chk_dn_pr <= 'b0;
        //data_chk_dn_pr_r <= 'b0;
        data_chk_dn_cmpl <= 'b0;
        //data_chk_dn_cmpl_r <= 'b0;        
    end
    else if (flow_type_s1 == 'd2) begin
        data_chk_dn_pr     <= data_chk_dn_i;
        //data_chk_dn_pr_r   <= data_chk_dn_pr;
        data_chk_dn_cmpl <= 'b0;
        //data_chk_dn_cmpl_r <= 'b0;            
    end
    else if ((flow_type_s1 == 'd1) & (~iob_ctl_cap_detected[0]) & (~barrier_cap_detected[0]) & (~iob_ctl_cap_detected[1]) & (~barrier_cap_detected[1])) begin
        data_chk_dn_pr     <= 'b0;
        //data_chk_dn_pr_r   <= 'b0;
        data_chk_dn_cmpl <= data_chk_dn_i;
        //data_chk_dn_cmpl_r <= data_chk_dn_cmpl;           
    end 
    else begin
        data_chk_dn_pr <= 'b0;
        //data_chk_dn_pr_r <= 'b0;
        data_chk_dn_cmpl <= 'b0;
        //data_chk_dn_cmpl_r <= 'b0;            
    end
end

always @(posedge clk)
begin
    if(!rst_n) 
    begin
        pr_pass_count_o   <= 'd0;
        pr_err_count_o    <= 'd0; 
        npr_pass_count_o  <= 'd0;
        npr_err_count_o   <= 'd0;
        cmpl_pass_count_o <= 'd0;
        cmpl_err_count_o  <= 'd0;
    end
    else if (inc_pr_err_count | inc_pr_err_count_p1) begin
            pr_pass_count_o         <= pr_pass_count_o ;
            pr_err_count_o          <= pr_err_count_o + 'd1 ;
        end
    else if (inc_pr_pass_count | inc_pr_pass_count_p1) begin
            pr_pass_count_o         <= pr_pass_count_o + 'd1;
            pr_err_count_o          <= pr_err_count_o ;
    end
    else if (inc_cmpl_err_count | inc_cmpl_err_count_p1) begin
            cmpl_pass_count_o         <= cmpl_pass_count_o ;
            cmpl_err_count_o          <= cmpl_err_count_o + 'd1 ;
        end
    else if (inc_cmpl_pass_count | inc_cmpl_pass_count_p1) begin
            cmpl_pass_count_o         <= cmpl_pass_count_o + 'd1;
            cmpl_err_count_o          <= cmpl_err_count_o ;
    end
    else if (inc_npr_err_count | inc_npr_err_count_p1) begin
            npr_pass_count_o         <= npr_pass_count_o ;
            npr_err_count_o          <= npr_err_count_o + 'd1 ;
        end
    else if (inc_npr_pass_count | inc_npr_pass_count_p1) begin
            npr_pass_count_o         <= npr_pass_count_o + 'd1;
            npr_err_count_o          <= npr_err_count_o ;
    end
end


`XSRREG_AXIMM(clk, rst_n, m_aximm00_rvalid_s1, m_aximm00_rvalid_i, 1'b0)
`XSRREG_AXIMM(clk, rst_n, m_aximm00_wvalid_s1, m_aximm00_wvalid_i, 1'b0)
`XSRREG_AXIMM(clk, rst_n, m_aximm00_awvalid_s1, m_aximm00_awvalid_i, 1'b0)

`XSRREG_AXIMM(clk, rst_n, s_aximm00_rvalid_s1, s_aximm00_rvalid_i, 1'b0)
`XSRREG_AXIMM(clk, rst_n, s_aximm00_wvalid_s1, s_aximm00_wvalid_i, 1'b0)

`XSRREG_AXIMM(clk, rst_n, s_aximm00_rlast_s1, s_aximm00_rlast_i, 1'b0)
`XSRREG_AXIMM(clk, rst_n, s_aximm00_wlast_s1, s_aximm00_wlast_i, 1'b0)

`XSRREG_AXIMM(clk, rst_n, m_aximm00_rlast_s1, m_aximm00_rlast_i, 1'b0)
`XSRREG_AXIMM(clk, rst_n, m_aximm00_wlast_s1, m_aximm00_wlast_i, 1'b0)


assign m_aximm00_rvalid_pulse = m_aximm00_rvalid_i & ~m_aximm00_rvalid_s1;
assign m_aximm00_wvalid_pulse = m_aximm00_wvalid_i & ~m_aximm00_wvalid_s1;
assign m_aximm00_awvalid_pulse = m_aximm00_awvalid_i & ~m_aximm00_awvalid_s1;

assign s_aximm00_rvalid_pulse = s_aximm00_rvalid_i & ~s_aximm00_rvalid_s1;
assign s_aximm00_wvalid_pulse = s_aximm00_wvalid_i & ~s_aximm00_wvalid_s1;

assign s_aximm00_rlast_pulse = s_aximm00_rlast_i & ~ s_aximm00_rlast_s1;
assign s_aximm00_wlast_pulse = s_aximm00_wlast_i & ~ s_aximm00_wlast_s1;

assign m_aximm00_rlast_pulse = m_aximm00_rlast_i & ~ m_aximm00_rlast_s1;
assign m_aximm00_wlast_pulse = m_aximm00_wlast_i & ~ m_aximm00_wlast_s1;
/////////////////////////////////////////////////////////////////////
//////////////////////        SEGMENT 0      ////////////////////////
/////////////////////////////////////////////////////////////////////
assign capsule_valid_pulse = capsule_valid_i & ~capsule_valid_s1;
assign ld_snapshot = capsule_valid_pulse ? 1'b1 : 1'b0;

`XSRREG_AXIMM(clk, rst_n, capsule_valid_s1, capsule_valid_i, 1'b0)
`XSRREG_AXIMM(clk, rst_n, capsule_valid_s2, capsule_valid_s1, 1'b0)
`XSRREG_AXIMM(clk, rst_n, capsule_valid_s3, capsule_valid_s2, 1'b0)
`XSRREG_AXIMM(clk, rst_n, capsule_valid_s4, capsule_valid_s3, 1'b0)
`XSRREG_AXIMM(clk, rst_n, capsule_valid_s5, capsule_valid_s4, 1'b0)
`XSRREG_AXIMM(clk, rst_n, capsule_valid_s6, capsule_valid_s5, 1'b0)
`XSRREG_AXIMM(clk, rst_n, data_chk_pass_s1, data_chk_pass_i, 1'b0)
`XSRREG_AXIMM(clk, rst_n, data_chk_err_s1, data_chk_err_i, 1'b0)

always@(posedge clk)
begin
    if(!rst_n)
        m_aximm00_arready_cnt_o <= 'd0;
    else if (m_aximm00_arready_i)
        m_aximm00_arready_cnt_o <= m_aximm00_arready_cnt_o +'d1;
    else 
        m_aximm00_arready_cnt_o <= m_aximm00_arready_cnt_o;
end


always@(posedge clk)
begin
    if(!rst_n)
        m_aximm00_awready_cnt_o <= 'd0;
    else if (m_aximm00_awready_i)
        m_aximm00_awready_cnt_o <= m_aximm00_awready_cnt_o +'d1;
    else 
        m_aximm00_awready_cnt_o <= m_aximm00_awready_cnt_o;
end


always@(posedge clk)
begin
    if(!rst_n)
        m_aximm00_arvalid_cnt_o <= 'd0;
    else if (m_aximm00_arvalid_i)
        m_aximm00_arvalid_cnt_o <= m_aximm00_arvalid_cnt_o +'d1;
    else 
        m_aximm00_arvalid_cnt_o <= m_aximm00_arvalid_cnt_o;
end

always@(posedge clk)
begin
    if(!rst_n)
        m_aximm00_awvalid_cnt_o <= 'd0;
    else if (m_aximm00_awvalid_pulse)
        m_aximm00_awvalid_cnt_o <= m_aximm00_awvalid_cnt_o +'d1;
    else 
        m_aximm00_awvalid_cnt_o <= m_aximm00_awvalid_cnt_o;
end


always@(posedge clk)
begin
    if(!rst_n)
        s_aximm00_arvalid_cnt_o <= 'd0;
    else if (s_aximm00_arvalid_i)
        s_aximm00_arvalid_cnt_o <= s_aximm00_arvalid_cnt_o +'d1;
    else 
        s_aximm00_arvalid_cnt_o <= s_aximm00_arvalid_cnt_o;
end

always@(posedge clk)
begin
    if(!rst_n)
        s_aximm00_awvalid_cnt_o <= 'd0;
    else if (s_aximm00_awvalid_i)
        s_aximm00_awvalid_cnt_o <= s_aximm00_awvalid_cnt_o +'d1;
    else 
        s_aximm00_awvalid_cnt_o <= s_aximm00_awvalid_cnt_o;
end



always@(posedge clk)
begin
    if(!rst_n)
        m_aximm00_wlast_cnt_o <= 'd0;
    else if (m_aximm00_wlast_pulse)
        m_aximm00_wlast_cnt_o <= m_aximm00_wlast_cnt_o +'d1;
    else 
        m_aximm00_wlast_cnt_o <= m_aximm00_wlast_cnt_o;
end

always@(posedge clk)
begin
    if(!rst_n)
        m_aximm00_rlast_cnt_o <= 'd0;
    else if (m_aximm00_rlast_pulse)
        m_aximm00_rlast_cnt_o <= m_aximm00_rlast_cnt_o +'d1;
    else 
        m_aximm00_rlast_cnt_o <= m_aximm00_rlast_cnt_o;
end



always@(posedge clk)
begin
    if(!rst_n)
        s_aximm00_wlast_cnt_o <= 'd0;
    else if (s_aximm00_wlast_pulse)
        s_aximm00_wlast_cnt_o <= s_aximm00_wlast_cnt_o +'d1;
    else 
        s_aximm00_wlast_cnt_o <= s_aximm00_wlast_cnt_o;
end

always@(posedge clk)
begin
    if(!rst_n)
        s_aximm00_rlast_cnt_o <= 'd0;
    else if (s_aximm00_rlast_pulse)
        s_aximm00_rlast_cnt_o <= s_aximm00_rlast_cnt_o +'d1;
    else 
        s_aximm00_rlast_cnt_o <= s_aximm00_rlast_cnt_o;
end





always@(posedge clk)
begin
    if(!rst_n)
        m_aximm00_wvalid_cnt_o <= 'd0;
    else if (m_aximm00_wvalid_pulse)
        m_aximm00_wvalid_cnt_o <= m_aximm00_wvalid_cnt_o +'d1;
    else 
        m_aximm00_wvalid_cnt_o <= m_aximm00_wvalid_cnt_o;
end

always@(posedge clk)
begin
    if(!rst_n)
        m_aximm00_rvalid_cnt_o <= 'd0;
    else if (m_aximm00_rvalid_pulse)
        m_aximm00_rvalid_cnt_o <= m_aximm00_rvalid_cnt_o +'d1;
    else 
        m_aximm00_rvalid_cnt_o <= m_aximm00_rvalid_cnt_o;
end




always@(posedge clk)
begin
    if(!rst_n)
        s_aximm00_wvalid_cnt_o <= 'd0;
    else if (s_aximm00_wvalid_pulse)
        s_aximm00_wvalid_cnt_o <= s_aximm00_wvalid_cnt_o +'d1;
    else 
        s_aximm00_wvalid_cnt_o <= s_aximm00_wvalid_cnt_o;
end

always@(posedge clk)
begin
    if(!rst_n)
        s_aximm00_rvalid_cnt_o <= 'd0;
    else if (s_aximm00_rvalid_pulse)
        s_aximm00_rvalid_cnt_o <= s_aximm00_rvalid_cnt_o +'d1;
    else 
        s_aximm00_rvalid_cnt_o <= s_aximm00_rvalid_cnt_o;
end


//assign csi_dw_len = sop_i ? csi_dw_len_i : 'd0;
always @(posedge clk)
begin
    if(!rst_n)
        csi_dw_len <= 'd0;
    else if (sop_i)
        csi_dw_len <= csi_dw_len_i;
    else
        csi_dw_len <= csi_dw_len;
end

`XSRREG_AXIMM(clk, rst_n, csi_dw_len_s1, csi_dw_len, 1'b0)
`XSRREG_AXIMM(clk, rst_n, csi_dw_len_s2, csi_dw_len_s1, 1'b0)
`XSRREG_AXIMM(clk, rst_n, csi_dw_len_s3, csi_dw_len_s2, 1'b0)
`XSRREG_AXIMM(clk, rst_n, csi_dw_len_s4, csi_dw_len_s3, 1'b0)

always @(posedge clk)
begin
    if(!rst_n)  begin
        num_data_chk_err  <= 'd0;
        num_data_chk_pass <= 'd0;
        end
    else if (csi_dw_len_s4=='h003) begin
        if (capsule_valid_s3 | capsule_valid_s4 | capsule_valid_s5 | capsule_valid_s6)  begin
            num_data_chk_err  <= num_data_chk_err + data_chk_err_i + data_chk_err_s1;
            num_data_chk_pass <= num_data_chk_pass + data_chk_pass_i + data_chk_pass_s1;
        end
    end
    else if (capsule_valid_s3 | capsule_valid_s4 | capsule_valid_s5 | capsule_valid_s6) begin
        num_data_chk_err  <= num_data_chk_err + data_chk_err_i;
        num_data_chk_pass <= num_data_chk_pass + data_chk_pass_i;
    end
    else begin
        num_data_chk_err  <= 'd0;
        num_data_chk_pass <= 'd0;
    end
end

`XSRREG_EN_AXIMM(clk, rst_n, flow_type_snapshot, flow_type_i, '0, ld_snapshot)
`XSRREG_EN_AXIMM(clk, rst_n, num_data_chk_err_snapshot, num_data_chk_err, '0, ((inc_cmpl_err_count & data_chk_dn_cmpl_r1[0])| (num_data_chk_err == 'd0)))
//`XSRREG_EN_AXIMM(clk, rst_n, num_data_chk_pass_snapshot, num_data_chk_pass, '0, ((inc_cmpl_pass_count & data_chk_dn_cmpl_r1[0]) | (num_data_chk_pass == 'd0)))


always @(posedge clk)
begin
    if(!rst_n)
        num_data_chk_pass_snapshot <= 'd0;
    else if ((chk_dn_count_cmpl_s1 == 'd0) ||  (num_data_chk_pass == 'd0))
        num_data_chk_pass_snapshot <= 'd0;
    else if (inc_cmpl_pass_count & data_chk_dn_cmpl_r1[0])// | (num_data_chk_pass == 'd0))
        num_data_chk_pass_snapshot <= num_data_chk_pass;
end
    
    
always @(posedge clk)
begin
    if(!rst_n)
        flow_type_snapshot_s1 <= 'd0;
    else 
        flow_type_snapshot_s1 <= flow_type_snapshot;
end



always @(posedge clk)
begin
    if(!rst_n) begin
        chk_dn_count_cmpl <= 'd0;
    end
    else if (data_chk_dn_cmpl[0]) begin
        chk_dn_count_cmpl <= chk_dn_count_cmpl + data_chk_dn_cmpl[0];
    end 
    else begin
        chk_dn_count_cmpl <= 'd0;
    end
end

always @(posedge clk)
begin
    if(!rst_n) begin
        chk_dn_count_pr <= 'd0;
    end
    else if (data_chk_dn_pr[0]) begin
        chk_dn_count_pr <= chk_dn_count_pr + data_chk_dn_pr[0];
    end 
    else begin
        chk_dn_count_pr <= 'd0;
    end
end




/*
always @(posedge clk)
begin
    if(!rst_n) begin
        chk_dn_count_pr <= 'd0;
        chk_dn_count_cmpl <= 'd0;
    end
    else if (capsule_valid_s6) begin
        chk_dn_count_pr <= chk_dn_count_pr + data_chk_dn_pr[0];
        chk_dn_count_cmpl <= chk_dn_count_cmpl + data_chk_dn_cmpl[0];
    end 
    else begin
        chk_dn_count_pr <= 'd0;
        chk_dn_count_cmpl <= 'd0;
    end
end
*/
always @(posedge clk)
begin
    if(!rst_n) 
    begin
        inc_pr_err_count <= 'd0;
        inc_pr_pass_count <= 'd0;
    end 
    else if (chk_dn_count_pr_s1 > 'd0) begin
        if (data_chk_dn_pr_r1[0] & (flow_type_s4 == 2'd2)) begin
            if (num_data_chk_err > num_data_chk_err_snapshot) 
                inc_pr_err_count <= 'd1;
            else if (num_data_chk_pass > num_data_chk_pass_snapshot)
                inc_pr_pass_count <= 'd1;
        end
        else begin
            inc_pr_err_count <= 'd0;
            inc_pr_pass_count <= 'd0;
        end
    end
    
    else if (data_chk_dn_pr_r1[0] & (flow_type_s4 == 2'd2)) begin
        if (num_data_chk_err > 'd0) 
            inc_pr_err_count <= 'd1;
        else if ((num_data_chk_pass > 'd0) & (num_data_chk_err == 'd0)) 
            inc_pr_pass_count <= 'd1;       
    end
    else begin
        inc_pr_err_count <= 'd0;
        inc_pr_pass_count <= 'd0;
    end 
end


always @(posedge clk)
begin
    if(!rst_n) 
    begin
        inc_cmpl_err_count <= 'd0;
        inc_cmpl_pass_count <= 'd0;
    end 
    else if (chk_dn_count_cmpl_s1 > 'd0) begin
        if (data_chk_dn_cmpl_r1[0] & (flow_type_s4 == 2'd1)) begin
            if (num_data_chk_err > num_data_chk_err_snapshot) 
                inc_cmpl_err_count <= 'd1;
            else if (num_data_chk_pass > num_data_chk_pass_snapshot)
                inc_cmpl_pass_count <= 'd1;
        end
        else begin
            inc_cmpl_err_count <= 'd0;
            inc_cmpl_pass_count <= 'd0;
        end
    end
    
    else if (data_chk_dn_cmpl_r1[0] & (flow_type_s4 == 2'd1)) begin
        if (num_data_chk_err > 'd0) 
            inc_cmpl_err_count <= 'd1;
        else if ((num_data_chk_pass > 'd0) & (num_data_chk_err == 'd0)) 
            inc_cmpl_pass_count <= 'd1;     
    end
    else begin
        inc_cmpl_err_count <= 'd0;
        inc_cmpl_pass_count <= 'd0;
    end 
end


always @(posedge clk)
begin
    if(!rst_n) 
    begin
        inc_npr_err_count <= 'd0;
        inc_npr_pass_count <= 'd0;
    end 
    
    else if (chk_dn_count > 'd0) begin
        if (data_chk_dn_r[0] & (flow_type_s3 == 2'd0)) begin
            if (num_data_chk_err > num_data_chk_err_snapshot) 
                inc_npr_err_count <= 'd1;
            else if (num_data_chk_pass > num_data_chk_pass_snapshot)
                inc_npr_pass_count <= 'd1;
        end
        else begin
            inc_npr_err_count <= 'd0;
            inc_npr_pass_count <= 'd0;
        end
    end
    
    else if (data_chk_dn_r[0] & (flow_type_s3 == 2'd0)) begin
        if (num_data_chk_err > 'd0) 
            inc_npr_err_count <= 'd1;
        else if ((num_data_chk_pass > 'd0) & (num_data_chk_err == 'd0)) 
            inc_npr_pass_count <= 'd1;      
    end
    else begin
        inc_npr_err_count <= 'd0;
        inc_npr_pass_count <= 'd0;
    end 
end




/////////////////////////////////////////////////////////////////////
//////////////////////        SEGMENT 1      ////////////////////////
/////////////////////////////////////////////////////////////////////
assign capsule_valid_p1_pulse = capsule_valid_p1_i & ~capsule_valid_p1_s1;
assign ld_snapshot_p1 = capsule_valid_p1_pulse ? 1'b1 : 1'b0;

`XSRREG_AXIMM(clk, rst_n, capsule_valid_p1_s1, capsule_valid_p1_i, 1'b0)
`XSRREG_AXIMM(clk, rst_n, capsule_valid_p1_s2, capsule_valid_p1_s1, 1'b0)
`XSRREG_AXIMM(clk, rst_n, capsule_valid_p1_s3, capsule_valid_p1_s2, 1'b0)
`XSRREG_AXIMM(clk, rst_n, capsule_valid_p1_s4, capsule_valid_p1_s3, 1'b0)
`XSRREG_AXIMM(clk, rst_n, capsule_valid_p1_s5, capsule_valid_p1_s4, 1'b0)
`XSRREG_AXIMM(clk, rst_n, capsule_valid_p1_s6, capsule_valid_p1_s5, 1'b0)





always @(posedge clk)
begin
    if(!rst_n)  begin
        num_data_chk_err_p1  <= 'd0;
        num_data_chk_pass_p1 <= 'd0;
        end
    else if (capsule_valid_p1_s3 | capsule_valid_p1_s4 | capsule_valid_p1_s5 | capsule_valid_p1_s6) begin
        num_data_chk_err_p1  <= num_data_chk_err_p1 + data_chk_err_p1_i;
        num_data_chk_pass_p1 <= num_data_chk_pass_p1 + data_chk_pass_p1_i;
    end
    else begin
        num_data_chk_err_p1  <= 'd0;
        num_data_chk_pass_p1 <= 'd0;
    end
end

`XSRREG_EN_AXIMM(clk, rst_n, flow_type_snapshot_p1, flow_type_p1_i, '0, ld_snapshot_p1)
`XSRREG_EN_AXIMM(clk, rst_n, num_data_chk_err_snapshot_p1, num_data_chk_err_p1, '0, (inc_cmpl_err_count_p1 | (num_data_chk_err_p1 == 'd0)))
`XSRREG_EN_AXIMM(clk, rst_n, num_data_chk_pass_snapshot_p1, num_data_chk_pass_p1, '0, (inc_cmpl_pass_count_p1 | (num_data_chk_pass_p1 == 'd0)))

always @(posedge clk)
begin
    if(!rst_n)
        flow_type_snapshot_p1_s1 <= 'd0;
    else 
        flow_type_snapshot_p1_s1 <= flow_type_snapshot_p1;
end

/*
always @(posedge clk)
begin
    if(!rst_n)
        chk_dn_count_p1 <= 'd0;
    else if (capsule_valid_p1_s6)
        chk_dn_count_p1 <= chk_dn_count_p1 + data_chk_dn[1];
    else 
        chk_dn_count_p1 <= 'd0;
end
*/

always @(posedge clk)
begin
    if(!rst_n) begin
        chk_dn_count_p1_pr <= 'd0;
        chk_dn_count_p1_cmpl <= 'd0;
    end
    else if (capsule_valid_p1_s6) begin
        chk_dn_count_p1_pr <= chk_dn_count_p1_pr + data_chk_dn_pr[1];
        chk_dn_count_p1_cmpl <= chk_dn_count_p1_cmpl + data_chk_dn_cmpl[1];
    end 
    else begin
        chk_dn_count_p1_pr <= 'd0;
        chk_dn_count_p1_cmpl <= 'd0;
    end
end

always @(posedge clk)
begin
    if(!rst_n) 
    begin
        inc_pr_err_count_p1 <= 'd0;
        inc_pr_pass_count_p1 <= 'd0;
    end 
    else if (chk_dn_count_p1_pr_s1 > 'd0) begin
        if (data_chk_dn_pr_r1[1] & (flow_type_p1_s4 == 2'd2)) begin
            if (num_data_chk_err_p1 > num_data_chk_err_snapshot_p1) 
                inc_pr_err_count_p1 <= 'd1;
            else if (num_data_chk_pass_p1 > num_data_chk_pass_snapshot_p1)
                inc_pr_pass_count_p1 <= 'd1;
        end
        else begin
            inc_pr_err_count_p1 <= 'd0;
            inc_pr_pass_count_p1 <= 'd0;
        end
    end
    
    else if (data_chk_dn_pr_r1[1] & (flow_type_p1_s4 == 2'd2)) begin
        if (num_data_chk_err_p1 > 'd0) 
            inc_pr_err_count_p1 <= 'd1;
        else if ((num_data_chk_pass_p1 > 'd0) & (num_data_chk_err_p1 == 'd0)) 
            inc_pr_pass_count_p1 <= 'd1;        
    end
    else begin
        inc_pr_err_count_p1 <= 'd0;
        inc_pr_pass_count_p1 <= 'd0;
    end 
end


always @(posedge clk)
begin
    if(!rst_n) 
    begin
        inc_cmpl_err_count_p1 <= 'd0;
        inc_cmpl_pass_count_p1 <= 'd0;
    end 
    else if (chk_dn_count_p1_cmpl_s1 > 'd0) begin
        if (data_chk_dn_cmpl_r1[1] & (flow_type_p1_s4 == 2'd1)) begin
            if (num_data_chk_err_p1 > num_data_chk_err_snapshot_p1) 
                inc_cmpl_err_count_p1 <= 'd1;
            else if (num_data_chk_pass_p1 > num_data_chk_pass_snapshot_p1)
                inc_cmpl_pass_count_p1 <= 'd1;
        end
        else begin
            inc_cmpl_err_count_p1 <= 'd0;
            inc_cmpl_pass_count_p1 <= 'd0;
        end
    end
    
    else if (data_chk_dn_cmpl_r1[1] & (flow_type_p1_s4 == 2'd1)) begin
        if (num_data_chk_err_p1 > 'd0) 
            inc_cmpl_err_count_p1 <= 'd1;
        else if ((num_data_chk_pass_p1 > 'd0) & (num_data_chk_err_p1 == 'd0)) 
            inc_cmpl_pass_count_p1 <= 'd1;      
    end
    else begin
        inc_cmpl_err_count_p1 <= 'd0;
        inc_cmpl_pass_count_p1 <= 'd0;
    end 
end


always @(posedge clk)
begin
    if(!rst_n) 
    begin
        inc_npr_err_count_p1 <= 'd0;
        inc_npr_pass_count_p1 <= 'd0;
    end 
    
    else if (chk_dn_count_p1 > 'd0) begin
        if (data_chk_dn_r[1] & (flow_type_p1_s3 == 2'd0)) begin
            if (num_data_chk_err_p1 > num_data_chk_err_snapshot_p1) 
                inc_npr_err_count_p1 <= 'd1;
            else if (num_data_chk_pass_p1 > num_data_chk_pass_snapshot_p1)
                inc_npr_pass_count_p1 <= 'd1;
        end
        else begin
            inc_npr_err_count_p1 <= 'd0;
            inc_npr_pass_count_p1 <= 'd0;
        end
    end
    
    else if (data_chk_dn_r[1] & (flow_type_p1_s3 == 2'd0)) begin
        if (num_data_chk_err_p1 > 'd0) 
            inc_npr_err_count_p1 <= 'd1;
        else if ((num_data_chk_pass_p1 > 'd0) & (num_data_chk_err_p1 == 'd0)) 
            inc_npr_pass_count_p1 <= 'd1;       
    end
    else begin
        inc_npr_err_count_p1 <= 'd0;
        inc_npr_pass_count_p1 <= 'd0;
    end 
end



        
endmodule       
