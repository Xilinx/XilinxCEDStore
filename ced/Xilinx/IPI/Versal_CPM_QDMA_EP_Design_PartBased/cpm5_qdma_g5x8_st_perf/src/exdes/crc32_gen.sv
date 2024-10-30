//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
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
//
// Project    : The Xilinx PCI Express DMA 
// File       : crc32_gen.sv
// Version    : 5.0
// NOTE       :
//              Modified to register tdata after masking to help reduce logic levels
//              This means we will incur an extra latency on the data generation
//              And incur extra flops to all ST_C2H interface
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

// From pciecoredefines.h
`define XSRREG_SYNC(clk, reset_n, q,d,rstval)        \
    always @(posedge clk)                        \
    begin                                        \
     if (reset_n == 1'b0)                        \
         q <= #(TCQ) rstval;                                \
     else                                        \
         `ifdef FOURVALCLKPROP                        \
            q <= #(TCQ) clk ? d : q;                        \
          `else                                        \
            q <= #(TCQ)  d;                                \
          `endif                                \
     end
`define XSRREG_SYNC_EN(clk, reset_n, q,d,rstval, en) \
    always @(posedge clk)      \
    begin                      \
     if (reset_n == 1'b0)      \
         q <= #(TCQ) rstval;   \
     else                      \
         `ifdef FOURVALCLKPROP \
            q <= #(TCQ) ((en & clk)  ? d : q); \
          `else                       \
            q <= #(TCQ) (en ? d : q); \
          `endif                      \
     end

// From dma5_axi4mm_axi_bridge.vh
`define XSRREG_XDMA(clk, reset_n, q,d,rstval)        \
`XSRREG_SYNC (clk, reset_n, q,d,rstval)
`define XSRREG_EN_XDMA(clk, reset_n, q,d,rstval, en)     \
`XSRREG_SYNC_EN(clk, reset_n, q,d,rstval, en)

module crc32_gen #(
    parameter MAX_DATA_WIDTH    = 512,
    parameter CRC_WIDTH         = 32,
    parameter QID_WIDTH         = 11,  // Must be 11. Queue ID bit width
    parameter TCQ               = 1,
    parameter MTY_BITS          = $clog2(MAX_DATA_WIDTH/8)
) (
    // Clock and Resetd
    input                                  clk,
    input                                  rst_n,
    input                                  in_par_err,
    input                                  in_misc_err,
    input                                  in_crc_dis,

// Replaced with full set bus below
/*
    input  [MAX_DATA_WIDTH-1:0]            in_data,
    input                                  in_vld,
    input                                  in_tlast,
    input  [MTY_BITS-1:0]                  in_mty,
    output logic [CRC_WIDTH-1:0]           out_crc
*/

  // C2H Input Signals from ST_C2H Module
  input        [MAX_DATA_WIDTH-1 :0]       s_axis_c2h_tdata_i,
  input                                    s_axis_c2h_ctrl_marker_i,
  input        [15:0]                      s_axis_c2h_ctrl_len_i,
  input        [QID_WIDTH-1:0]             s_axis_c2h_ctrl_qid_i,
  input                                    s_axis_c2h_ctrl_user_trig_i,
  input                                    s_axis_c2h_ctrl_dis_cmpt_i,
  input                                    s_axis_c2h_ctrl_imm_data_i,
  input                                    s_axis_c2h_tvalid_i,
  output logic                             s_axis_c2h_tready_i,
  input                                    s_axis_c2h_tlast_i,
  input        [MTY_BITS-1:0]              s_axis_c2h_mty_i,
  
  // C2H Output Signals to QDMA IP
  output logic [MAX_DATA_WIDTH-1 :0]       s_axis_c2h_tdata_o,
  output logic                             s_axis_c2h_ctrl_marker_o,
  output logic [15:0]                      s_axis_c2h_ctrl_len_o,
  output logic [QID_WIDTH-1:0]             s_axis_c2h_ctrl_qid_o,
  output logic                             s_axis_c2h_ctrl_user_trig_o,
  output logic                             s_axis_c2h_ctrl_dis_cmpt_o,
  output logic                             s_axis_c2h_ctrl_imm_data_o,
  output logic                             s_axis_c2h_tvalid_o,
  input                                    s_axis_c2h_tready_o,
  output logic                             s_axis_c2h_tlast_o,
  output logic [MTY_BITS-1:0]              s_axis_c2h_mty_o,
  output logic [CRC_WIDTH-1:0]             s_axis_c2h_tcrc_o

);


  localparam CRC_POLY = 32'b00000100110000010001110110110111;

  logic [CRC_WIDTH-1:0]             crc_var, crc_reg;
  logic                             sop_nxt,sop;
  logic                             out_par_err, out_par_err_reg;
  logic                             out_misc_err, out_misc_err_reg;
  logic                             vld_reg, tlast_reg;

  logic [MAX_DATA_WIDTH-1:0]        data_mask;
  logic [MAX_DATA_WIDTH-1:0]        data_masked;
  logic [MAX_DATA_WIDTH-1:0]        data_masked_reg;
/* Replaced with registered version below
  always_comb begin
    data_mask   = ~in_tlast ? {MAX_DATA_WIDTH{1'b1}} : {MAX_DATA_WIDTH{1'b1}} >> {in_mty, 3'b0};
    data_masked = in_data & data_mask;
    crc_var     = crc_reg;
    sop_nxt     = sop;
    if (in_vld) begin
      if (sop) 
        crc_var = {CRC_WIDTH{1'b1}};
        
      for (int i=0; i<MAX_DATA_WIDTH; i=i+1) begin
        crc_var = {crc_var[CRC_WIDTH-1-1:0], 1'b0} ^ (CRC_POLY & {CRC_WIDTH{crc_var[CRC_WIDTH-1]^data_masked[MAX_DATA_WIDTH-i-1]}});
      end
      sop_nxt = in_tlast;
    end
  end
*/
  always_comb begin
    data_mask   = ~s_axis_c2h_tlast_i ? {MAX_DATA_WIDTH{1'b1}} : {MAX_DATA_WIDTH{1'b1}} >> {s_axis_c2h_mty_i, 3'b0};
    data_masked = s_axis_c2h_tdata_i & data_mask;
    crc_var     = crc_reg;
    sop_nxt     = sop;
    if (vld_reg) begin // This need to be asserted only when in_vld & in_rdy
      if (sop) 
        crc_var = {CRC_WIDTH{1'b1}};
        
      for (int i=0; i<MAX_DATA_WIDTH; i=i+1) begin
        crc_var = {crc_var[CRC_WIDTH-1-1:0], 1'b0} ^ (CRC_POLY & {CRC_WIDTH{crc_var[CRC_WIDTH-1]^data_masked_reg[MAX_DATA_WIDTH-i-1]}});
      end
      sop_nxt = tlast_reg;
    end
  end

  always_comb begin
    out_par_err  = out_par_err_reg;
    out_misc_err = out_misc_err_reg;
    if (s_axis_c2h_tvalid_i) begin
      out_par_err  = sop ? in_par_err : out_par_err_reg | in_par_err;
      out_misc_err = sop ? in_misc_err : out_misc_err_reg | in_misc_err;
    end
  end

  `XSRREG_XDMA(clk, rst_n, crc_reg, crc_var, 'h0)
  `XSRREG_XDMA(clk, rst_n, sop, sop_nxt, 'h1)
  `XSRREG_XDMA(clk, rst_n, out_par_err_reg, out_par_err, 'h0)
  `XSRREG_XDMA(clk, rst_n, out_misc_err_reg, out_misc_err, 'h0)
  `XSRREG_EN_XDMA(clk, rst_n, data_masked_reg, data_masked, 'h0, s_axis_c2h_tready_o)
  `XSRREG_XDMA(clk, rst_n, vld_reg, s_axis_c2h_tvalid_i & s_axis_c2h_tready_o, 'h0)
  `XSRREG_EN_XDMA(clk, rst_n, tlast_reg, s_axis_c2h_tlast_i, 'h0, s_axis_c2h_tready_o)

  //----------------------------------------------------------------
  // Update/Corrupt CRC for Parity and User Errors
  // Corrupt CRC LSB 2 bits for parity error
  // Corrupt CRC all bits for misc error
  //----------------------------------------------------------------
  always_comb begin
    s_axis_c2h_tcrc_o          = crc_var;
    if (in_crc_dis)
      s_axis_c2h_tcrc_o[1:0]   = {out_misc_err,out_par_err};
    else if (out_par_err) 
      s_axis_c2h_tcrc_o[1:0]   = crc_var[1:0] ^ 2'h3;
    else if (out_misc_err) 
      s_axis_c2h_tcrc_o        = crc_var ^ {CRC_WIDTH{1'b1}};
  end

  `XSRREG_EN_XDMA(clk, rst_n, s_axis_c2h_tdata_o, s_axis_c2h_tdata_i, 'h0, s_axis_c2h_tready_o)
  `XSRREG_EN_XDMA(clk, rst_n, s_axis_c2h_ctrl_marker_o, s_axis_c2h_ctrl_marker_i, 'h0, s_axis_c2h_tready_o)
  `XSRREG_EN_XDMA(clk, rst_n, s_axis_c2h_ctrl_len_o, s_axis_c2h_ctrl_len_i, 'h0, s_axis_c2h_tready_o)
  `XSRREG_EN_XDMA(clk, rst_n, s_axis_c2h_ctrl_qid_o, s_axis_c2h_ctrl_qid_i, 'h0, s_axis_c2h_tready_o)
  `XSRREG_EN_XDMA(clk, rst_n, s_axis_c2h_ctrl_user_trig_o, s_axis_c2h_ctrl_user_trig_i, 'h0, s_axis_c2h_tready_o)
  `XSRREG_EN_XDMA(clk, rst_n, s_axis_c2h_ctrl_dis_cmpt_o, s_axis_c2h_ctrl_dis_cmpt_i, 'h0, s_axis_c2h_tready_o)
  `XSRREG_EN_XDMA(clk, rst_n, s_axis_c2h_ctrl_imm_data_o, s_axis_c2h_ctrl_imm_data_i, 'h0, s_axis_c2h_tready_o)
  `XSRREG_EN_XDMA(clk, rst_n, s_axis_c2h_tvalid_o, s_axis_c2h_tvalid_i, 'h0, s_axis_c2h_tready_o)
  `XSRREG_EN_XDMA(clk, rst_n, s_axis_c2h_tlast_o, s_axis_c2h_tlast_i, 'h0, s_axis_c2h_tready_o)
  `XSRREG_EN_XDMA(clk, rst_n, s_axis_c2h_mty_o, s_axis_c2h_mty_i, 'h0, s_axis_c2h_tready_o)

  always_comb begin
    s_axis_c2h_tready_i        = s_axis_c2h_tready_o;
  end

endmodule // crc32_gen
