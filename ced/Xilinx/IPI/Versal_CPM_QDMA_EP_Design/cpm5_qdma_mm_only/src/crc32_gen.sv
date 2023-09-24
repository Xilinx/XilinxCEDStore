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

// From dma5_axi4mm_axi_bridge.vh
`define XSRREG_XDMA(clk, reset_n, q,d,rstval)        \
`XSRREG_SYNC (clk, reset_n, q,d,rstval) \

module crc32_gen #(
    parameter MAX_DATA_WIDTH    = 512,
    parameter CRC_WIDTH         = 32,
    parameter TCQ               = 1,
    parameter MTY_BITS          = $clog2(MAX_DATA_WIDTH/8)
) (
    // Clock and Resetd
    input                                  clk,
    input                                  rst_n,
    input                                  in_par_err,
    input                                  in_misc_err,
    input                                  in_crc_dis,


    input  [MAX_DATA_WIDTH-1:0]            in_data,
    input                                  in_vld,
    input                                  in_tlast,
    input  [MTY_BITS-1:0]                  in_mty,
    output logic [CRC_WIDTH-1:0]           out_crc
);


  localparam CRC_POLY = 32'b00000100110000010001110110110111;

  logic [CRC_WIDTH-1:0]             crc_var, crc_reg;
  logic                             sop_nxt,sop;
  logic                             out_par_err, out_par_err_reg;
  logic                             out_misc_err, out_misc_err_reg;

  logic [MAX_DATA_WIDTH-1:0]        data_mask;
  logic [MAX_DATA_WIDTH-1:0]        data_masked;
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

  always_comb begin
    out_par_err  = out_par_err_reg;
    out_misc_err = out_misc_err_reg;
    if (in_vld) begin
      out_par_err  = sop ? in_par_err : out_par_err_reg | in_par_err;
      out_misc_err = sop ? in_misc_err : out_misc_err_reg | in_misc_err;
    end
  end

  `XSRREG_XDMA(clk, rst_n, crc_reg, crc_var, 'h0)
  `XSRREG_XDMA(clk, rst_n, sop, sop_nxt, 'h1)
  `XSRREG_XDMA(clk, rst_n, out_par_err_reg, out_par_err, 'h0)
  `XSRREG_XDMA(clk, rst_n, out_misc_err_reg, out_misc_err, 'h0)

  //----------------------------------------------------------------
  // Update/Corrupt CRC for Parity and User Errors
  // Corrupt CRC LSB 2 bits for parity error
  // Corrupt CRC all bits for misc error
  //----------------------------------------------------------------
  always_comb begin
    out_crc          = crc_var;
    if (in_crc_dis)
      out_crc[1:0]   = {out_misc_err,out_par_err};
    else if (out_par_err) 
      out_crc[1:0]   = crc_var[1:0] ^ 2'h3;
    else if (out_misc_err) 
      out_crc        = crc_var ^ {CRC_WIDTH{1'b1}};
  end

endmodule // crc32_gen
