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
`ifndef CDX5N_DEFINES_VH
`define CDX5N_DEFINES_VH

`timescale 1 ps / 1 ps


////////////////////
// BASE Flop Macros
`define XSRREG_SYNC_CDX(clk, reset_n, q,d,rstval) \
always @(posedge clk) \
begin \
  if (reset_n == 1'b0) \
    q <= #(TCQ) rstval; \
  else \
`ifdef FOURVALCLKPROP \
    q <= #(TCQ) clk ? d : q; \
`else \
    q <= #(TCQ)  d; \
`endif \
end

`define XSRREG_ASYNC_CDX(clk, reset_n, q,d,rstval) \
always @(posedge clk or negedge reset_n) \
begin \
  if (reset_n == 1'b0) \
    q <= #(TCQ) rstval; \
  else \
`ifdef FOURVALCLKPROP \
    q <= #(TCQ) clk ? d : q; \
`else \
    q <= #(TCQ)  d; \
`endif \
end

`define XSRREG_SYNC_EN_CDX(clk, reset_n, q,d,rstval, en) \
always @(posedge clk) \
begin \
  if (reset_n == 1'b0) \
    q <= #(TCQ) rstval; \
  else \
`ifdef FOURVALCLKPROP \
    q <= #(TCQ) ((en & clk)  ? d : q); \
`else \
    q <= #(TCQ) (en ? d : q); \
`endif \
end

`define XSRREG_ASYNC_EN_CDX(clk, reset_n, q,d,rstval, en) \
always @(posedge clk or negedge reset_n) \
begin \
  if (reset_n == 1'b0) \
    q <= #(TCQ) rstval; \
  else \
`ifdef FOURVALCLKPROP \
    q <= #(TCQ) ((en & clk)  ? d : q); \
`else \
    q <= #(TCQ) (en ? d : q); \
`endif \
end

`define XPREG_NORESET_CDX(clk,q,d) \
always @(posedge clk) \
begin \
`ifdef FOURVALCLKPROP \
    q <= #(TCQ) clk? d : q; \
`else \
    q <= #(TCQ) d; \
`endif \
end

`define XLREGS_SYNC_CDX(clk, reset_n) \
always @(posedge clk)

`define XLREGS_ASYNC_CDX(clk, reset_n) \
always @(posedge clk or negedge reset_n)


///////////////////////////
// SOFT vs HARD Flop Macros
`define XSRREG_CDX(clk, reset_n, q,d,rstval)        \
`ifdef SOFT_IP  \
`XSRREG_SYNC_CDX (clk, reset_n, q,d,rstval) \
`else   \
`XSRREG_ASYNC_CDX (clk, reset_n, q,d,rstval)  \
`endif 

`define XSRREG(clk, reset_n, q,d,rstval)        \
`ifdef SOFT_IP  \
`XSRREG_SYNC_CDX (clk, reset_n, q,d,rstval) \
`else   \
`XSRREG_ASYNC_CDX (clk, reset_n, q,d,rstval)  \
`endif 

`define XSRREG_AXIMM(clk, reset_n, q,d,rstval)        \
`ifdef SOFT_IP  \
`XSRREG_SYNC_CDX (clk, reset_n, q,d,rstval) \
`else   \
`XSRREG_ASYNC_CDX (clk, reset_n, q,d,rstval)  \
`endif 

`define XSRREG_EN_CDX(clk, reset_n, q,d,rstval, en)     \
`ifdef SOFT_IP \
`XSRREG_SYNC_EN_CDX(clk, reset_n, q,d,rstval, en) \
`else \
`XSRREG_ASYNC_EN_CDX(clk, reset_n, q,d,rstval, en) \
`endif

`define XSRREG_EN_AXIMM(clk, reset_n, q,d,rstval, en)     \
`ifdef SOFT_IP \
`XSRREG_SYNC_EN_CDX(clk, reset_n, q,d,rstval, en) \
`else \
`XSRREG_ASYNC_EN_CDX(clk, reset_n, q,d,rstval, en) \
`endif

`define XSRREG_HARD(clk, reset_n, q,d,rstval)        \
`ifdef SOFT_IP  \
`XPREG_NORESET_CDX(clk, q,d) \
`else   \
`XSRREG_ASYNC_CDX (clk, reset_n, q,d,rstval)  \
`endif

`define XSRREG_SYNC_HARD(clk, reset_n, sync_reset_n, q,d,rstval)        \
`ifdef SOFT_IP  \
`XSRREG_SYNC_CDX(clk, sync_reset_n, q,d, rstval) \
`else   \
`XSRREG_ASYNC_CDX (clk, reset_n, q,d,rstval)  \
`endif

`define XSRREG_HARD_CLR(clk, reset_n, q,d)        \
`ifdef SOFT_IP  \
`XPREG_NORESET_CDX(clk, q,d) \
`else   \
`XSRREG_ASYNC_CDX (clk, reset_n, q,d,'h0)  \
`endif


`define XLREG_CDX(clk, reset_n) \
`ifdef SOFT_IP \
`XLREGS_SYNC_CDX(clk, reset_n) \
`else \
`XLREGS_ASYNC_CDX(clk, reset_n)  \
`endif

`define XLREG(clk, reset_n) \
`ifdef SOFT_IP \
`XLREGS_SYNC_CDX(clk, reset_n) \
`else \
`XLREGS_ASYNC_CDX(clk, reset_n)  \
`endif

`define XLREG_AXIMM(clk, reset_n) \
`ifdef SOFT_IP \
`XLREGS_SYNC_CDX(clk, reset_n) \
`else \
`XLREGS_ASYNC_CDX(clk, reset_n)  \
`endif

`define XLREG_HARD(clk, reset_n) \
`ifdef SOFT_IP \
always @(posedge clk) \
if (0) begin \
`else \
`XLREGS_ASYNC_CDX(clk, reset_n)  \
if (~reset_n ) begin \
`endif

`define XLREG_END \
end else



`define XNRREG_AXIMM(clk,q,d)                            \
    always @(posedge clk)                            \
    begin                                            \
         `ifdef FOURVALCLKPROP                            \
            q <= #(TCQ) clk? d : q;                            \
          `else                                            \
            q <= #(TCQ) d;                                    \
          `endif                                    \
     end

`define XNRREG_EN_AXIMM(clk,q,d,en)     \
    always @(posedge clk)                            \
    begin                                            \
         `ifdef FOURVALCLKPROP                            \
            q <= #(TCQ) ((en & clk)  ? d : q);                    \
          `else                                            \
            q <= #(TCQ) (en ? d : q);                            \
          `endif                                    \
     end

// AXI Defines
`define SIZE64 0
`define SIZE128 1
`define SIZE256 2
`define SIZE512 3
`define CQ_USER_FBELO 0
`define CQ_USER_FBEHI 3
`define CQ_USER_LBELO 4
`define CQ_USER_LBEHI 7
`define CQ_USER_LBELO_512 8
`define CQ_USER_LBEHI_512 11
`define CQ_USER_BELO 8
`define CQ_USER_BEHI (CQ_USER_BELO +31)
`define CQ_USER_PARLO 53
`define CQ_USER_PARLO_512 119
`define CQ_USER_PARHI (CQ_USER_PARLO +31)
`define AXIS_MEM_READ 4'h0
`define AXIS_MEM_WRITE 4'h1
`define AXIS_IO_READ 4'h2
`define AXIS_IO_WRITE 4'h3
`define AXIS_IO_WRITE 4'h3
`define AXIS_FETCH_ADD 4'h4
`define AXIS_UCOND_SWAP 4'h5
`define AXIS_COMP_SWAP 4'h6
`define AXIS_READ_LCK 4'h7
`define AXIS_CFGRD_TYPE0 4'h8
`define AXIS_CFGRD_TYPE1 4'h9
`define AXIS_CFGWR_TYPE0 4'ha
`define AXIS_CFGWR_TYPE1 4'hb
`define AXIS_MSG_GEN 4'hc
`define AXIS_MSG_VNDDEF 4'hd
`define AXIS_MSG_ATS 4'he
`define AXIS_RSVD 4'hf


`define AXIMM_RRESP_OK 2'b00
`define AXIMM_RRESP_EXOK 2'b01
`define AXIMM_RRESP_SLVERR 2'b10
`define AXIMM_RRESP_DECERR 2'b11

`define DMA5_RAM_SIZE_DIST      128
`define DMA5_RAM_SIZE_BLK       1024
`define DMA5_RAM_DEP_BLK        64


`endif // CDX5N_DEFINES_VH
