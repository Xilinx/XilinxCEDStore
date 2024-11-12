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
