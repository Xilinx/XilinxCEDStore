
//-----------------------------------------------------------------------------
//
// (c) Copyright 1995, 2007, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : Versal PCI Express Integrated Block
// File       : BMD_AXIST_RX.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

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
