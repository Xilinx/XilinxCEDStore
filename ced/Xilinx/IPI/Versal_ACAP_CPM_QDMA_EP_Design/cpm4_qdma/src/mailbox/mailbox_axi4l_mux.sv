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

`ifndef MAILBOX_AXL4L_MUX
`define MAILBOX_AXL4L_MUX

`include "mailbox_defines.svh"
`include "qdma_pcie_dma_attr_defines.vh"

`timescale 1ns/1ps
/*******************************************************************************/
// mailbox_axi4l_mux.sv
//  1. parsing axi4lite transactions from qdma
//  2. forward transaction from DAM BAR to m_axi4l_dma2mailbox
//  3. forward transaction from none DMA BAR to m_axi4l_dma2ext
/*******************************************************************************/
module qdma_v2_0_1_mailbox_axi4l_mux #(
  parameter BARLITE_MB_PF0 = 6'b0,
  parameter BARLITE_MB_PF1 = 6'b0,
  parameter BARLITE_MB_PF2 = 6'b0,
  parameter BARLITE_MB_PF3 = 6'b0,
  parameter MSIX_PF_ADDSTR    = 32'h00004000,
  parameter MSIX_PF_ADDEND    = 32'h00005000,
  parameter MSIX_VF_ADDSTR    = 32'h00000000,
  parameter MSIX_VF_ADDEND    = 32'h00001000
)(
 input                 clk,
 input                 reset_n,
 attr_dma_t            attr_dma,
 mailbox_axi4lite_if.s s_axi4l_dma,     
 mailbox_axi4lite_if.m m_axi4l_dma2mailbox, 
 mailbox_axi4lite_if.m m_axi4l_dma2msixt, 
 mailbox_axi4lite_if.m m_axi4l_dma2ext     
);

logic    [3:0][5:0]   pf_barlite_int;
logic    [3:0][5:0]   pf_barlite_MB;
logic    [3:0][5:0]   pf_vf_barlite_int;

assign pf_barlite_int        = attr_dma.pf_barlite_int;
assign pf_barlite_MB[0][5:0] = BARLITE_MB_PF0;
assign pf_barlite_MB[1][5:0] = BARLITE_MB_PF1;
assign pf_barlite_MB[2][5:0] = BARLITE_MB_PF2;
assign pf_barlite_MB[3][5:0] = BARLITE_MB_PF3;
assign pf_vf_barlite_int     = attr_dma.pf_vf_barlite_int;

/*******************************************************************************/
// Wr channel
/*******************************************************************************/
reg   wch_is_active;
wire  wch_is_dma_nxt;
wire  wch_is_msix_nxt;
reg   wch_is_dma;
reg   wch_is_msix;
wire  [7:0] wfnc = s_axi4l_dma.awuser[7:0];
   
assign wch_is_dma_nxt  = fn_is_dma(s_axi4l_dma.awuser,pf_barlite_int,pf_barlite_MB,pf_vf_barlite_int);
assign wch_is_msix_nxt  = wfnc < 4 ? (s_axi4l_dma.awaddr[16:0] >= MSIX_PF_ADDSTR[16:0]) & (s_axi4l_dma.awaddr[16:0] < MSIX_PF_ADDEND[16:0]) :
			  (s_axi4l_dma.awaddr[13:0] >= MSIX_VF_ADDSTR[13:0]) & (s_axi4l_dma.awaddr[13:0] < MSIX_VF_ADDEND[13:0]) ;

always_ff@(posedge clk)
begin
  if(~reset_n)
    wch_is_dma <= '0;
  else if (s_axi4l_dma.awvalid & ~wch_is_active)
    wch_is_dma <= wch_is_dma_nxt & ~wch_is_msix_nxt;;
end
always_ff@(posedge clk)
begin
  if(~reset_n)
    wch_is_msix <= '0;
  else if (s_axi4l_dma.awvalid & ~wch_is_active)
    wch_is_msix <= wch_is_dma_nxt & wch_is_msix_nxt;;
end

always_ff@(posedge clk)
begin
  if(~reset_n)
    wch_is_active <= '0;
  else if (s_axi4l_dma.bvalid & s_axi4l_dma.bready) 
    wch_is_active <= '0;
  else if (s_axi4l_dma.awvalid)
    wch_is_active <= 1'b1;
end

assign s_axi4l_dma.awready         = wch_is_active ? (wch_is_msix ? m_axi4l_dma2msixt.awready : wch_is_dma ? m_axi4l_dma2mailbox.awready : m_axi4l_dma2ext.awready) :1'b0;
assign m_axi4l_dma2mailbox.awvalid = wch_is_active & wch_is_dma & s_axi4l_dma.awvalid;
assign m_axi4l_dma2mailbox.awuser  = s_axi4l_dma.awuser;
assign m_axi4l_dma2mailbox.awaddr  = s_axi4l_dma.awaddr;
assign m_axi4l_dma2ext.awvalid     = wch_is_active & ~(wch_is_dma | wch_is_msix) & s_axi4l_dma.awvalid;
assign m_axi4l_dma2ext.awuser      = s_axi4l_dma.awuser;
assign m_axi4l_dma2ext.awaddr      = s_axi4l_dma.awaddr;

assign s_axi4l_dma.wready         = wch_is_active ? (wch_is_msix ? m_axi4l_dma2msixt.wready : wch_is_dma ? m_axi4l_dma2mailbox.wready : m_axi4l_dma2ext.wready) :1'b0;
assign m_axi4l_dma2mailbox.wvalid = wch_is_active & wch_is_dma & s_axi4l_dma.wvalid;
assign m_axi4l_dma2mailbox.wdata  = s_axi4l_dma.wdata;
assign m_axi4l_dma2mailbox.wstrb  = s_axi4l_dma.wstrb;
assign m_axi4l_dma2mailbox.wuser  = s_axi4l_dma.wuser;
assign m_axi4l_dma2ext.wvalid     = wch_is_active & ~(wch_is_dma | wch_is_msix) & s_axi4l_dma.wvalid;
assign m_axi4l_dma2ext.wdata      = s_axi4l_dma.wdata;
assign m_axi4l_dma2ext.wstrb      = s_axi4l_dma.wstrb;
assign m_axi4l_dma2ext.wuser      = s_axi4l_dma.wuser;

assign s_axi4l_dma.bvalid         =  wch_is_active ? (wch_is_msix ? m_axi4l_dma2msixt.bvalid : wch_is_dma ? m_axi4l_dma2mailbox.bvalid : m_axi4l_dma2ext.bvalid) :1'b0;
assign s_axi4l_dma.bresp          =  wch_is_msix ? m_axi4l_dma2msixt.bresp : wch_is_dma ? m_axi4l_dma2mailbox.bresp: m_axi4l_dma2ext.bresp;
assign s_axi4l_dma.buser          =  wch_is_msix ? m_axi4l_dma2msixt.buser : wch_is_dma ? m_axi4l_dma2mailbox.buser: m_axi4l_dma2ext.buser;
assign m_axi4l_dma2ext.bready     =  ~(wch_is_dma | wch_is_msix) & s_axi4l_dma.bready;
assign m_axi4l_dma2mailbox.bready =  wch_is_dma & s_axi4l_dma.bready;

// MSIX Table
assign m_axi4l_dma2msixt.awvalid = wch_is_active & wch_is_msix & s_axi4l_dma.awvalid;
assign m_axi4l_dma2msixt.awuser  = wfnc < 4 ? s_axi4l_dma.awuser[7:0] | {'0,s_axi4l_dma.awaddr[14],8'h0} : s_axi4l_dma.awuser[7:0] | {'0,s_axi4l_dma.awaddr[11],8'h0} ;
assign m_axi4l_dma2msixt.awaddr  = s_axi4l_dma.awaddr[11:0];

assign m_axi4l_dma2msixt.wvalid = wch_is_active & wch_is_msix & s_axi4l_dma.wvalid;
assign m_axi4l_dma2msixt.wdata  = s_axi4l_dma.wdata;
assign m_axi4l_dma2msixt.wstrb  = s_axi4l_dma.wstrb;
assign m_axi4l_dma2msixt.wuser  = s_axi4l_dma.wuser;

assign m_axi4l_dma2msixt.bready =  wch_is_msix & s_axi4l_dma.bready;
   
/*******************************************************************************/
// Rd channel
/*******************************************************************************/
wire rch_is_dma_nxt;
wire rch_is_msix_nxt;
reg  rch_is_dma;
reg  rch_is_msix;
reg  rch_is_active;
wire  [7:0] rfnc = s_axi4l_dma.aruser[7:0];

assign rch_is_dma_nxt  = fn_is_dma(s_axi4l_dma.aruser,pf_barlite_int,pf_barlite_MB,pf_vf_barlite_int);
assign rch_is_msix_nxt  = rfnc < 4 ? (s_axi4l_dma.araddr[16:0] >= MSIX_PF_ADDSTR[16:0]) & (s_axi4l_dma.araddr[16:0] < MSIX_PF_ADDEND[16:0]) :
			  (s_axi4l_dma.araddr[13:0] >= MSIX_VF_ADDSTR[13:0]) & (s_axi4l_dma.araddr[13:0] < MSIX_VF_ADDEND[13:0]) ;

always_ff@(posedge clk)
begin
  if(~reset_n)
    rch_is_dma <= '0;
  else if (s_axi4l_dma.arvalid & ~rch_is_active)
    rch_is_dma <= rch_is_dma_nxt & ~rch_is_msix_nxt;
end

always_ff@(posedge clk)
begin
  if(~reset_n)
    rch_is_msix <= '0;
  else if (s_axi4l_dma.arvalid & ~rch_is_active)
    rch_is_msix <= rch_is_dma_nxt & rch_is_msix_nxt;
end
   
always_ff@(posedge clk)
begin
  if(~reset_n)
    rch_is_active <= '0;
  else if (s_axi4l_dma.rvalid & s_axi4l_dma.rready) 
    rch_is_active <= '0;
  else if (s_axi4l_dma.arvalid)
    rch_is_active <= 1'b1;
end

assign s_axi4l_dma.arready         = rch_is_active ? (rch_is_msix ? m_axi4l_dma2msixt.arready : rch_is_dma ? m_axi4l_dma2mailbox.arready : m_axi4l_dma2ext.arready) : 1'b0;
assign m_axi4l_dma2mailbox.aruser  = s_axi4l_dma.aruser;
assign m_axi4l_dma2mailbox.araddr  = s_axi4l_dma.araddr;
assign m_axi4l_dma2mailbox.arvalid = s_axi4l_dma.arvalid & rch_is_active & rch_is_dma;
assign m_axi4l_dma2ext.aruser      = s_axi4l_dma.aruser;
assign m_axi4l_dma2ext.araddr      = s_axi4l_dma.araddr;
assign m_axi4l_dma2ext.arvalid     = s_axi4l_dma.arvalid & rch_is_active & ~(rch_is_dma | rch_is_msix);

assign s_axi4l_dma.rvalid         = rch_is_active ? (rch_is_msix ? m_axi4l_dma2msixt.rvalid : rch_is_dma ? m_axi4l_dma2mailbox.rvalid : m_axi4l_dma2ext.rvalid) : 1'b0;
assign s_axi4l_dma.ruser          = rch_is_msix ? m_axi4l_dma2msixt.ruser : rch_is_dma ? m_axi4l_dma2mailbox.ruser : m_axi4l_dma2ext.ruser;
assign s_axi4l_dma.rdata          = rch_is_msix ? m_axi4l_dma2msixt.rdata : rch_is_dma ? m_axi4l_dma2mailbox.rdata : m_axi4l_dma2ext.rdata;
assign s_axi4l_dma.rresp          = rch_is_msix ? m_axi4l_dma2msixt.rresp : rch_is_dma ? m_axi4l_dma2mailbox.rresp : m_axi4l_dma2ext.rresp;
assign m_axi4l_dma2mailbox.rready = rch_is_dma & rch_is_active & s_axi4l_dma.rready;
assign m_axi4l_dma2ext.rready     = ~(rch_is_dma | rch_is_msix) & rch_is_active & s_axi4l_dma.rready;

//MSIX Table
assign m_axi4l_dma2msixt.aruser  = rfnc < 4 ? s_axi4l_dma.aruser[7:0] | {'0,s_axi4l_dma.araddr[14],8'h0} : s_axi4l_dma.aruser[7:0] | {'0,s_axi4l_dma.araddr[11],8'h0};
// GTZ: set start addr for PBA & MSIX
assign m_axi4l_dma2msixt.araddr  = rfnc < 4 ? {18'h0, s_axi4l_dma.araddr[13:0]} : {21'h0, s_axi4l_dma.araddr[10:0]};
// safer but more complex logic - save for now
//assign m_axi4l_dma2msixt.araddr  = ~m_axi4l_dma2msixt.aruser[8] ? s_axi4l_dma.araddr : rfnc < 4 ? {18'h0, s_axi4l_dma.araddr[13:0]} : {21'h0, s_axi4l_dma.araddr[10:0]};
// backup
//assign m_axi4l_dma2msixt.araddr  = s_axi4l_dma.araddr;
// --- GTZ -- end ----------
assign m_axi4l_dma2msixt.arvalid = s_axi4l_dma.arvalid & rch_is_active & rch_is_msix;

assign m_axi4l_dma2msixt.rready = rch_is_msix & rch_is_active & s_axi4l_dma.rready;

/*******************************************************************************/
// Functions
/*******************************************************************************/
function [7:0] fn_3_bin2onehot;
  input [2:0] bin;
  begin
    case(bin) 
      0 :  fn_3_bin2onehot =  8'h0001 <<  0;
      1 :  fn_3_bin2onehot =  8'h0001 <<  1;
      2 :  fn_3_bin2onehot =  8'h0001 <<  2;
      3 :  fn_3_bin2onehot =  8'h0001 <<  3;
      4 :  fn_3_bin2onehot =  8'h0001 <<  4;
      5 :  fn_3_bin2onehot =  8'h0001 <<  5;
      6 :  fn_3_bin2onehot =  8'h0001 <<  6;
      7 :  fn_3_bin2onehot =  8'h0001 <<  7;
    endcase
  end
endfunction

//function to check if the transanction is coming for an DMA BAR
function fn_is_dma;
  input mailbox_axil_user_t  axil_user; 
  input [3:0][5:0]           pf_barlite_int;
  input [3:0][5:0]           pf_barlite_MB;
  input [3:0][5:0]           pf_vf_barlite_int;
  logic [5:0] pf_dma_bar;
  logic [5:0] vf_dma_bar;
  logic [7:0] bar_dec;
  logic [5:0] cur_bar;
  logic       fn_is_pf;
  logic       pf_is_dma;
  logic       vf_is_dma;
begin
     fn_is_pf   = (axil_user.func[7:2] == 6'b0);
     pf_dma_bar = (pf_barlite_int[axil_user.func[1:0]] | pf_barlite_MB[axil_user.func[1:0]]);
     vf_dma_bar = pf_vf_barlite_int[axil_user.vfg];

     bar_dec = fn_3_bin2onehot(axil_user.bardec);
     cur_bar = bar_dec[5:0];

     pf_is_dma = |(cur_bar & pf_dma_bar);
     vf_is_dma = |(cur_bar & vf_dma_bar);

     fn_is_dma = fn_is_pf ? pf_is_dma : vf_is_dma;
end
endfunction
endmodule
`endif
//  parameter BARLITE_MB_PF0 = 6'b0,
//  parameter BARLITE_MB_PF1 = 6'b0,
//  parameter BARLITE_MB_PF2 = 6'b0,
//  parameter BARLITE_MB_PF3 = 6'b0
//)(
// input                 clk,
// input                 reset_n,
// attr_dma_t            attr_dma,
// mailbox_axi4lite_if.s s_axi4l_dma,     
// mailbox_axi4lite_if.m m_axi4l_dma2mailbox, 
// mailbox_axi4lite_if.m m_axi4l_dma2ext     
//);

//logic    [3:0][5:0]   pf_barlite_int;
//logic    [3:0][5:0]   pf_barlite_MB;
//logic    [3:0][5:0]   pf_vf_barlite_int;

//assign pf_barlite_int        = attr_dma.pf_barlite_int;
//assign pf_barlite_MB[0][5:0] = BARLITE_MB_PF0;
//assign pf_barlite_MB[1][5:0] = BARLITE_MB_PF1;
//assign pf_barlite_MB[2][5:0] = BARLITE_MB_PF2;
//assign pf_barlite_MB[3][5:0] = BARLITE_MB_PF3;
//assign pf_vf_barlite_int     = attr_dma.pf_vf_barlite_int;

///*******************************************************************************/
//// Wr channel
///*******************************************************************************/
//reg   wch_is_active;
//wire  wch_is_dma_nxt;
//reg   wch_is_dma;

//assign wch_is_dma_nxt  = fn_is_dma(s_axi4l_dma.awuser,pf_barlite_int,pf_barlite_MB,pf_vf_barlite_int);

//always_ff@(posedge clk)
//begin
//  if(~reset_n)
//    wch_is_dma <= '0;
//  else if (s_axi4l_dma.awvalid & ~wch_is_active)
//    wch_is_dma <= wch_is_dma_nxt;
//end

//always_ff@(posedge clk)
//begin
//  if(~reset_n)
//    wch_is_active <= '0;
//  else if (s_axi4l_dma.bvalid & s_axi4l_dma.bready) 
//    wch_is_active <= '0;
//  else if (s_axi4l_dma.awvalid)
//    wch_is_active <= 1'b1;
//end

//assign s_axi4l_dma.awready         = wch_is_active ? (wch_is_dma ? m_axi4l_dma2mailbox.awready : m_axi4l_dma2ext.awready) :1'b0;
//assign m_axi4l_dma2mailbox.awvalid = wch_is_active & wch_is_dma & s_axi4l_dma.awvalid;
//assign m_axi4l_dma2mailbox.awuser  = s_axi4l_dma.awuser;
//assign m_axi4l_dma2mailbox.awaddr  = {16'b0, s_axi4l_dma.awaddr[15:0]};  //In Everest, we append numbers on top to identifu PF vs VF and the func number
//assign m_axi4l_dma2ext.awvalid     = wch_is_active & ~wch_is_dma & s_axi4l_dma.awvalid;
//assign m_axi4l_dma2ext.awuser      = s_axi4l_dma.awuser;
//assign m_axi4l_dma2ext.awaddr      = s_axi4l_dma.awaddr;

//assign s_axi4l_dma.wready         = wch_is_active ? (wch_is_dma ? m_axi4l_dma2mailbox.wready : m_axi4l_dma2ext.wready) :1'b0;
//assign m_axi4l_dma2mailbox.wvalid = wch_is_active & wch_is_dma & s_axi4l_dma.wvalid;
//assign m_axi4l_dma2mailbox.wdata  = s_axi4l_dma.wdata;
//assign m_axi4l_dma2mailbox.wstrb  = s_axi4l_dma.wstrb;
//assign m_axi4l_dma2mailbox.wuser  = s_axi4l_dma.wuser;
//assign m_axi4l_dma2ext.wvalid     = wch_is_active & ~wch_is_dma & s_axi4l_dma.wvalid;
//assign m_axi4l_dma2ext.wdata      = s_axi4l_dma.wdata;
//assign m_axi4l_dma2ext.wstrb      = s_axi4l_dma.wstrb;
//assign m_axi4l_dma2ext.wuser      = s_axi4l_dma.wuser;

//assign s_axi4l_dma.bvalid         =  wch_is_active ? (wch_is_dma ? m_axi4l_dma2mailbox.bvalid : m_axi4l_dma2ext.bvalid) :1'b0;
//assign s_axi4l_dma.bresp          =  wch_is_dma ? m_axi4l_dma2mailbox.bresp: m_axi4l_dma2ext.bresp;
//assign s_axi4l_dma.buser          =  wch_is_dma ? m_axi4l_dma2mailbox.buser: m_axi4l_dma2ext.buser;
//assign m_axi4l_dma2ext.bready     =  ~wch_is_dma & s_axi4l_dma.bready;
//assign m_axi4l_dma2mailbox.bready =  wch_is_dma & s_axi4l_dma.bready;

///*******************************************************************************/
//// Rd channel
///*******************************************************************************/
//wire rch_is_dma_nxt;
//reg  rch_is_dma;
//reg  rch_is_active;

//assign rch_is_dma_nxt  = fn_is_dma(s_axi4l_dma.aruser,pf_barlite_int,pf_barlite_MB,pf_vf_barlite_int);
//always_ff@(posedge clk)
//begin
//  if(~reset_n)
//    rch_is_dma <= '0;
//  else if (s_axi4l_dma.arvalid & ~rch_is_active)
//    rch_is_dma <= rch_is_dma_nxt;
//end

//always_ff@(posedge clk)
//begin
//  if(~reset_n)
//    rch_is_active <= '0;
//  else if (s_axi4l_dma.rvalid & s_axi4l_dma.rready) 
//    rch_is_active <= '0;
//  else if (s_axi4l_dma.arvalid)
//    rch_is_active <= 1'b1;
//end

//assign s_axi4l_dma.arready         = rch_is_active ? (rch_is_dma ? m_axi4l_dma2mailbox.arready : m_axi4l_dma2ext.arready) : 1'b0;
//assign m_axi4l_dma2mailbox.aruser  = s_axi4l_dma.aruser;
//assign m_axi4l_dma2mailbox.araddr  = {16'b0, s_axi4l_dma.araddr[15:0]};  //In Everest, we append numbers on top to identifu PF vs VF and the func number
//assign m_axi4l_dma2mailbox.arvalid = s_axi4l_dma.arvalid & rch_is_active & rch_is_dma;
//assign m_axi4l_dma2ext.aruser      = s_axi4l_dma.aruser;
//assign m_axi4l_dma2ext.araddr      = s_axi4l_dma.araddr;
//assign m_axi4l_dma2ext.arvalid     = s_axi4l_dma.arvalid & rch_is_active & ~rch_is_dma;

//assign s_axi4l_dma.rvalid         = rch_is_active ? (rch_is_dma ? m_axi4l_dma2mailbox.rvalid : m_axi4l_dma2ext.rvalid) : 1'b0;
//assign s_axi4l_dma.ruser          = rch_is_dma ? m_axi4l_dma2mailbox.ruser : m_axi4l_dma2ext.ruser;
//assign s_axi4l_dma.rdata          = rch_is_dma ? m_axi4l_dma2mailbox.rdata : m_axi4l_dma2ext.rdata;
//assign s_axi4l_dma.rresp          = rch_is_dma ? m_axi4l_dma2mailbox.rresp : m_axi4l_dma2ext.rresp;
//assign m_axi4l_dma2mailbox.rready = rch_is_dma & rch_is_active & s_axi4l_dma.rready;
//assign m_axi4l_dma2ext.rready     = ~rch_is_dma & rch_is_active & s_axi4l_dma.rready;

///*******************************************************************************/
//// Functions
///*******************************************************************************/
//function [7:0] fn_3_bin2onehot;
//  input [2:0] bin;
//  begin
//    case(bin) 
//      0 :  fn_3_bin2onehot =  8'h0001 <<  0;
//      1 :  fn_3_bin2onehot =  8'h0001 <<  1;
//      2 :  fn_3_bin2onehot =  8'h0001 <<  2;
//      3 :  fn_3_bin2onehot =  8'h0001 <<  3;
//      4 :  fn_3_bin2onehot =  8'h0001 <<  4;
//      5 :  fn_3_bin2onehot =  8'h0001 <<  5;
//      6 :  fn_3_bin2onehot =  8'h0001 <<  6;
//      7 :  fn_3_bin2onehot =  8'h0001 <<  7;
//    endcase
//  end
//endfunction

////function to check if the transanction is coming for an DMA BAR
//function fn_is_dma;
//  input mailbox_axil_user_t  axil_user; 
//  input [3:0][5:0]           pf_barlite_int;
//  input [3:0][5:0]           pf_barlite_MB;
//  input [3:0][5:0]           pf_vf_barlite_int;
//  logic [5:0] pf_dma_bar;
//  logic [5:0] vf_dma_bar;
//  logic [7:0] bar_dec;
//  logic [5:0] cur_bar;
//  logic       fn_is_pf;
//  logic       pf_is_dma;
//  logic       vf_is_dma;
//begin
//     fn_is_pf   = (axil_user.func[7:3] == 6'b0);
//     pf_dma_bar = (pf_barlite_int[axil_user.func[1:0]] | pf_barlite_MB[axil_user.func[1:0]]);
//     vf_dma_bar = pf_vf_barlite_int[axil_user.vfg];

//     bar_dec = fn_3_bin2onehot(axil_user.bardec);
//     cur_bar = bar_dec[5:0];

//     pf_is_dma = |(cur_bar & pf_dma_bar);
//     vf_is_dma = |(cur_bar & vf_dma_bar);

//     fn_is_dma = fn_is_pf ? pf_is_dma : vf_is_dma;
//end
//endfunction
//endmodule
//`endif

