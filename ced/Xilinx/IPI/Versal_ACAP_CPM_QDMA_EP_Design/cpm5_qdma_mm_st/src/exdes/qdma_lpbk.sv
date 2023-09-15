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

`timescale 1ps/1ps
//`include "qdma_axi4mm_axi_bridge_exdes.vh"
//`include "pciedmacoredefines_exdes.vh"
//`include "qdma_defines_exdes.vh"
//`include "mdma_defines_exdes.svh"
`include "qdma_stm_defines.svh"

module   qdma_lpbk #(
    parameter MAX_DATA_WIDTH    = 512,
    parameter TDEST_BITS        = 16,
    parameter TCQ               = 0
) (
    // Clock and Reset
    input                                           clk,
    input                                           rst_n,

    //Input from QDMA
    input  [MAX_DATA_WIDTH-1:0]                     in_axis_tdata,
    input  mdma_h2c_axis_tuser_exdes_t                    in_axis_tuser,
    input                                           in_axis_tlast,
    input                                           in_axis_tvalid,
    output logic                                    in_axis_tready,

    //HDR output to QDMA
    output c2h_stub_std_cmp_t                       out_axis_cmp_data,
    output c2h_stub_std_cmp_ctrl_t                  out_axis_cmp_ctrl,
    output logic                                    out_axis_cmp_tlast,
    output logic                                    out_axis_cmp_tvalid,
    input                                           out_axis_cmp_tready,

    //PLD output to QDMA
    output mdma_c2h_axis_data_exdes_t                     out_axis_pld_data,
    output mdma_c2h_axis_ctrl_exdes_t                     out_axis_pld_ctrl,
    output logic [$clog2(MAX_DATA_WIDTH/8)-1:0]     out_axis_pld_mty,
    output logic                                    out_axis_pld_tlast,
    output logic                                    out_axis_pld_tvalid,
    input                                           out_axis_pld_tready
);



    //----------------------------------------------------------------
    //declarations
    //----------------------------------------------------------------
    //H2C stub
    //in
    logic [MAX_DATA_WIDTH-1:0]              h2c_stub_in_axis_tdata;
    mdma_h2c_axis_tuser_exdes_t                   h2c_stub_in_axis_tuser;
    logic                                   h2c_stub_in_axis_tlast;
    logic                                   h2c_stub_in_axis_tvalid;
    logic                                   h2c_stub_in_axis_tready;
    //out
    logic [MAX_DATA_WIDTH-1:0]              h2c_stub_out_axis_tdata;
    logic                                   h2c_stub_out_axis_tvalid;
    logic [TDEST_BITS-1:0]                  h2c_stub_out_axis_tdest;
    logic                                   h2c_stub_out_axis_tuser;
    logic                                   h2c_stub_out_axis_tlast;
    logic                                   h2c_stub_out_axis_tready;

    //LPBK
    //in
    logic [MAX_DATA_WIDTH-1:0]              lpbk_in_axis_tdata;
    logic                                   lpbk_in_axis_tvalid;
    logic [TDEST_BITS-1:0]                  lpbk_in_axis_tdest;
    logic                                   lpbk_in_axis_tuser;
    logic                                   lpbk_in_axis_tlast;
    logic                                   lpbk_in_axis_tready;
    //out
    logic [MAX_DATA_WIDTH-1:0]              lpbk_out_axis_tdata;
    logic                                   lpbk_out_axis_tuser;
    logic                                   lpbk_out_axis_tlast;
    logic                                   lpbk_out_axis_tvalid;
    logic                                   lpbk_out_axis_tready;

    //C2H stub
    //in
    logic [MAX_DATA_WIDTH-1:0]              c2h_stub_in_axis_tdata;
    logic                                   c2h_stub_in_axis_tuser;
    logic                                   c2h_stub_in_axis_tlast;
    logic                                   c2h_stub_in_axis_tvalid;
    logic                                   c2h_stub_in_axis_tready;
    //cmp out
    c2h_stub_std_cmp_t                      c2h_stub_out_axis_cmp_data;
    c2h_stub_std_cmp_ctrl_t                 c2h_stub_out_axis_cmp_ctrl;
    logic                                   c2h_stub_out_axis_cmp_tlast;
    logic                                   c2h_stub_out_axis_cmp_tvalid;
    logic                                   c2h_stub_out_axis_cmp_tready;
    //pld out
    mdma_c2h_axis_data_exdes_t                    c2h_stub_out_axis_pld_data;
    mdma_c2h_axis_ctrl_exdes_t                    c2h_stub_out_axis_pld_ctrl;
    logic [$clog2(MAX_DATA_WIDTH/8)-1:0]    c2h_stub_out_axis_pld_mty;
    logic                                   c2h_stub_out_axis_pld_tlast;
    logic                                   c2h_stub_out_axis_pld_tvalid;
    logic                                   c2h_stub_out_axis_pld_tready;
    //----------------------------------------------------------------



    //----------------------------------------------------------------
    // local connections
    //----------------------------------------------------------------
    always_comb begin
        h2c_stub_in_axis_tdata          = in_axis_tdata;
        h2c_stub_in_axis_tuser          = in_axis_tuser;
        h2c_stub_in_axis_tlast          = in_axis_tlast;
        h2c_stub_in_axis_tvalid         = in_axis_tvalid;
        in_axis_tready                  = h2c_stub_in_axis_tready;

        lpbk_in_axis_tdata              = h2c_stub_out_axis_tdata;
        lpbk_in_axis_tvalid             = h2c_stub_out_axis_tvalid;
        lpbk_in_axis_tdest              = h2c_stub_out_axis_tdest;
        lpbk_in_axis_tuser              = h2c_stub_out_axis_tuser;
        lpbk_in_axis_tlast              = h2c_stub_out_axis_tlast;
        h2c_stub_out_axis_tready        = lpbk_in_axis_tready;

        c2h_stub_in_axis_tdata          = lpbk_out_axis_tdata;
        c2h_stub_in_axis_tuser          = lpbk_out_axis_tuser;
        c2h_stub_in_axis_tlast          = lpbk_out_axis_tlast;
        c2h_stub_in_axis_tvalid         = lpbk_out_axis_tvalid;
        lpbk_out_axis_tready            = c2h_stub_in_axis_tready;

        out_axis_cmp_data               = c2h_stub_out_axis_cmp_data;
        out_axis_cmp_ctrl               = c2h_stub_out_axis_cmp_ctrl;
        out_axis_cmp_tlast              = c2h_stub_out_axis_cmp_tlast;
        out_axis_cmp_tvalid             = c2h_stub_out_axis_cmp_tvalid;
        c2h_stub_out_axis_cmp_tready    = out_axis_cmp_tready;

        out_axis_pld_data               = c2h_stub_out_axis_pld_data;
        out_axis_pld_ctrl               = c2h_stub_out_axis_pld_ctrl;
        out_axis_pld_mty                = c2h_stub_out_axis_pld_mty;
        out_axis_pld_tlast              = c2h_stub_out_axis_pld_tlast;
        out_axis_pld_tvalid             = c2h_stub_out_axis_pld_tvalid;
        c2h_stub_out_axis_pld_tready    = out_axis_pld_tready;
    end
    //----------------------------------------------------------------



     qdma_stm_h2c_stub #(
        .MAX_DATA_WIDTH         (MAX_DATA_WIDTH),
        .TDEST_BITS             (TDEST_BITS),
        .TCQ                    (TCQ)
    ) stm_h2c_stub (
        .clk                        (clk),
        .rst_n                      (rst_n),

        .in_axis_tdata              (h2c_stub_in_axis_tdata ),
        .in_axis_tuser              (h2c_stub_in_axis_tuser ),
        .in_axis_tlast              (h2c_stub_in_axis_tlast ),
        .in_axis_tvalid             (h2c_stub_in_axis_tvalid),
        .in_axis_tready             (h2c_stub_in_axis_tready),

        .out_axis_tdata             (h2c_stub_out_axis_tdata ),
        .out_axis_tvalid            (h2c_stub_out_axis_tvalid),
        .out_axis_tdest             (h2c_stub_out_axis_tdest ),
        .out_axis_tuser             (h2c_stub_out_axis_tuser ),
        .out_axis_tlast             (h2c_stub_out_axis_tlast ),
        .out_axis_tready            (h2c_stub_out_axis_tready)
    );

     qdma_stm_lpbk #(
        .MAX_DATA_WIDTH         (MAX_DATA_WIDTH),
        .TDEST_BITS             (TDEST_BITS),
        .TCQ                    (TCQ)
    ) qdma_stm_lpbk_inst (
        .clk                        (clk),
        .rst_n                      (rst_n),

        .in_axis_tdata              (lpbk_in_axis_tdata ),
        .in_axis_tvalid             (lpbk_in_axis_tvalid),
        .in_axis_tdest              (lpbk_in_axis_tdest ),
        .in_axis_tuser              (lpbk_in_axis_tuser ),
        .in_axis_tlast              (lpbk_in_axis_tlast ),
        .in_axis_tready             (lpbk_in_axis_tready),

        .out_axis_tdata             (lpbk_out_axis_tdata ),
        .out_axis_tuser             (lpbk_out_axis_tuser ),
        .out_axis_tlast             (lpbk_out_axis_tlast ),
        .out_axis_tvalid            (lpbk_out_axis_tvalid),
        .out_axis_tready            (lpbk_out_axis_tready)
    );

     qdma_stm_c2h_stub #(
        .MAX_DATA_WIDTH         (MAX_DATA_WIDTH),
        .TDEST_BITS             (TDEST_BITS),
        .TCQ                    (TCQ)
    ) stm_c2h_stub (
        .clk                        (clk),
        .rst_n                      (rst_n),

        .in_axis_tdata              (c2h_stub_in_axis_tdata ),
        .in_axis_tuser              (c2h_stub_in_axis_tuser ),
        .in_axis_tlast              (c2h_stub_in_axis_tlast ),
        .in_axis_tvalid             (c2h_stub_in_axis_tvalid),
        .in_axis_tready             (c2h_stub_in_axis_tready),

        .out_axis_cmp_data          (c2h_stub_out_axis_cmp_data  ),
        .out_axis_cmp_ctrl          (c2h_stub_out_axis_cmp_ctrl  ),
        .out_axis_cmp_tlast         (c2h_stub_out_axis_cmp_tlast ),
        .out_axis_cmp_tvalid        (c2h_stub_out_axis_cmp_tvalid),
        .out_axis_cmp_tready        (c2h_stub_out_axis_cmp_tready),

        .out_axis_pld_data          (c2h_stub_out_axis_pld_data  ),
        .out_axis_pld_ctrl          (c2h_stub_out_axis_pld_ctrl  ),
        .out_axis_pld_mty           (c2h_stub_out_axis_pld_mty   ),
        .out_axis_pld_tlast         (c2h_stub_out_axis_pld_tlast ),
        .out_axis_pld_tvalid        (c2h_stub_out_axis_pld_tvalid),
        .out_axis_pld_tready        (c2h_stub_out_axis_pld_tready)
    );
endmodule


