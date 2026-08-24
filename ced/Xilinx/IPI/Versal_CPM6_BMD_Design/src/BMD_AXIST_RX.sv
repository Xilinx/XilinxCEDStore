////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
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
////////////////////////////////////////////////////////////////////////

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_RX.sv
//--
//-- Description: Instantiates RW and CPL RX modules
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_RX
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
#(
    parameter logic             IF_CMP_PARITY_CHECK = 1'b0
)(
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic                        init_rst_i,

    // RX RW
    input  logic                        mmio_valid,
    input  rx_fifo_intf                 mmio_slot,
    output logic                        mmio_rd_en,

    input  logic                        wr_busy,
    output logic [10:0]                 addr,
    output logic [3:0]                  wr_be,
    output logic [3:0]                  rd_be,
    output logic [31:0]                 wr_data,
    output logic                        wr_en,
    output logic                        req_compl,
    output logic                        req_compl_wd,
    output logic                        req_compl_ur,
    output logic [2:0]                  req_tc,
    output logic [9:0]                  req_len,
    output logic [13:0]                 req_lookup_id,

    // RX CPL
    input  rx_intf                                  rx_cpl,
    output logic [($clog2(NUM_SLOTS)>>1):0]         tag_valid,
    output logic [($clog2(NUM_SLOTS)>>1):0][9:0]    tag_released,
    output logic                                    read_done,
    input  logic [31:0]                             cpld_data,
    input  logic [15:0]                             mrd_count,
    output logic [31:0]                             cpl_count,
    output logic [31:0]                             cpl_data_dw_count,
    output logic                                    read_dma_err,
    output logic [15:0]                             cpl_ur_count,
    output logic [9:0]                              cpl_ur_tag,

    output logic [31:0]                             debug_cpl,
    output logic [31:0]                             debug_rw
);

BMD_AXIST_RX_RW #(
    .IF_CMP_PARITY_CHECK        ( IF_CMP_PARITY_CHECK )
) EP_RX_RW (
    .clk                        ( clk ),
    .rst_n                      ( rst_n ),

    .mmio_valid                 ( mmio_valid ),
    .mmio_slot                  ( mmio_slot ),
    .mmio_rd_en                 ( mmio_rd_en ),

    .req_compl                  ( req_compl ),
    .req_compl_wd               ( req_compl_wd ),
    .req_compl_ur               ( req_compl_ur ),
    .req_tc                     ( req_tc ),
    .req_len                    ( req_len ),
    .addr                       ( addr ),
    .wr_be                      ( wr_be ),
    .rd_be                      ( rd_be ),
    .wr_data                    ( wr_data ),
    .wr_en                      ( wr_en ),
    .wr_busy                    ( wr_busy ),
    .req_lookup_id              ( req_lookup_id ),
    .debug                      ( debug_rw )
);

BMD_AXIST_RX_CPL EP_RX_CPL (
    .clk                        ( clk ),
    .rst_n                      ( rst_n ),
    .init_rst_i                 ( init_rst_i ),
    .rx_cpl                     ( rx_cpl ),
    .tag_valid                  ( tag_valid ),
    .tag_released               ( tag_released ),
    .read_done                  ( read_done ),
    .cpld_data                  ( cpld_data ),
    .mrd_count                  ( mrd_count ),
    .cpl_count                  ( cpl_count ),
    .cpl_data_dw_count          ( cpl_data_dw_count ),
    .read_dma_err               ( read_dma_err ),
    .cpl_ur_count               ( cpl_ur_count ),
    .cpl_ur_tag                 ( cpl_ur_tag ),

    .debug                      ( debug_cpl )
);

endmodule // BMD_AXIST_RX
