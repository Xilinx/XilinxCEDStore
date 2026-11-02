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

`timescale 1ps / 1ps

import pcie_str_pkg::*;
import pcie_rp_pkg::*;
import pcie_intf_pkg::*;

module completor_wrapper #(
    // parameters
    parameter NUM_SLOTS        = 3,
    parameter MAX_PAYLOAD_SIZE = 128,
    parameter ADDR_WIDTH       = 64,
    parameter DATA_WIDTH       = 32,
    parameter CHECKER_DEPTH    = 1024,
    parameter CHECKER_ADDR_WIDTH = 7,
    parameter CHECKER_DATA_WIDTH = 32,
    parameter ERROR_CNT_WIDTH  = 16,
    parameter TAG_COUNT        = 32,
    parameter ACTUAL_PAYLOAD_SIZE_SLOT = 2,
    parameter ACTUAL_PAYLOAD_SIZE_BYTE = 128
) (
    // ports
    input  logic                                                    clk,
    input  logic                                                    rst_n,
    input  logic                                                    link_down,

    // RX Interface signals
    input rx_intf                                                   rx_if,

    // RAM interface
    input   logic [CHECKER_DATA_WIDTH-1:0]                          cfg_checker_ram_rd_data,
    output  logic [$clog2(CHECKER_DEPTH)-1:0]                       cfg_checker_ram_rd_addr,
    output  logic                                                   cfg_checker_ram_rd_en,

    input   logic [CHECKER_ADDR_WIDTH+CHECKER_DATA_WIDTH-1:0]       mem_checker_ram_rd_data,
    output  logic [$clog2(CHECKER_DEPTH)-1:0]                       mem_checker_ram_rd_addr,
    output  logic                                                   mem_checker_ram_rd_en,

    // Tag interface
    output logic [$clog2(TAG_COUNT)-1:0]                            free_tag,
    output logic                                                    free_tag_valid,

    // Credit management
    output logic [NUM_SLOTS-1:0]                                    credits_to_return,

    // Error
    output error_counters_t                                         error_counts,

    // config mem handler
    input  logic [15:0]                                             ep_cfg_count,
    output logic                                                    cpl_received,
    output logic [DATA_WIDTH-1:0]                                   cpl_to_config_mem_handler,
    output logic                                                    ep_cfg_match,

    input logic [$clog2(TAG_COUNT)-1:0]                              tag_to_match,
    input logic                                                      bar_read_done

);

    rx_cpl_intf [NUM_SLOTS-1:0]                 read_fifo;
    logic       [NUM_SLOTS-1:0]                 rd_en_out;
    logic       [NUM_SLOTS-1:0]                 fifo_empty;
    logic       [NUM_SLOTS-1:0]                 fifo_almost_empty;
    logic       [NUM_SLOTS-1:0]                 fifo_full;
    logic       [NUM_SLOTS-1:0]                 wr_en_out;
    rx_cpl_intf [NUM_SLOTS-1:0]                 wr_cpl_fifo;
    logic       [NUM_SLOTS-1:0]                 overflow;
    logic       [NUM_SLOTS-1:0]                 underflow;

    logic                                       total_fifo_empty;
    logic                                       total_fifo_almost_empty;

    cpl_checker #(
        .NUM_SLOTS                  (NUM_SLOTS),
        .MAX_PAYLOAD_SIZE           (MAX_PAYLOAD_SIZE),
        .ADDR_WIDTH                 (ADDR_WIDTH),
        .DATA_WIDTH                 (DATA_WIDTH),
        .CHECKER_DEPTH              (CHECKER_DEPTH),
        .CHECKER_ADDR_WIDTH         (CHECKER_ADDR_WIDTH),
        .CHECKER_DATA_WIDTH         (CHECKER_DATA_WIDTH),
        .ERROR_CNT_WIDTH            (ERROR_CNT_WIDTH),
        .TAG_COUNT                  (TAG_COUNT),
        .ACTUAL_PAYLOAD_SIZE_SLOT   (ACTUAL_PAYLOAD_SIZE_SLOT),
        .ACTUAL_PAYLOAD_SIZE_BYTE   (ACTUAL_PAYLOAD_SIZE_BYTE)
    ) cpl_checker_inst (
        .clk                        (clk),
        .rst_n                      (rst_n),
        .link_down                  (link_down),
        .cfg_checker_ram_rd_data    (cfg_checker_ram_rd_data),
        .cfg_checker_ram_rd_en      (cfg_checker_ram_rd_en),
        .cfg_checker_ram_rd_addr    (cfg_checker_ram_rd_addr),
        .mem_checker_ram_rd_data    (mem_checker_ram_rd_data),
        .mem_checker_ram_rd_en      (mem_checker_ram_rd_en),
        .mem_checker_ram_rd_addr    (mem_checker_ram_rd_addr),
        .free_tag_valid             (free_tag_valid),
        .free_tag                   (free_tag),
        .credits_to_return          (credits_to_return),
        .cpl_received               (cpl_received),
        .cpl_to_config_mem_handler  (cpl_to_config_mem_handler),
        .error_counts               (error_counts),
        .ep_cfg_count               (ep_cfg_count),
        .ep_cfg_match               (ep_cfg_match),

        // Read FIFO interface
        .read_fifo                  (read_fifo),
        .total_fifo_empty           (total_fifo_empty),
        .total_fifo_almost_empty    (total_fifo_almost_empty),
        .rd_en_out                  (rd_en_out),

        .tag_to_match               (tag_to_match),
        .bar_read_done              (bar_read_done)
    );

    completor completor_xpm_inst (
        // Connect ports
        .clk                    (clk),
        .rst_n                  (rst_n),
        .link_down              (link_down),
        .rx_if                  (rx_if),
        .wr_en_out              (wr_en_out),
        .wr_cpl_fifo            (wr_cpl_fifo),
        .fifo_full              (fifo_full)
    );

    assign total_fifo_empty = &fifo_empty;
    assign total_fifo_almost_empty = &fifo_almost_empty;

    RX_CPL_FIFO #(
        .NUM_SLOTS(NUM_SLOTS)
    ) rx_cpl_fifo_inst (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .link_down              (link_down),
        .wr_en_out              (wr_en_out),
        .wr_cpl_fifo            (wr_cpl_fifo),
        .fifo_full              (fifo_full),
        .read_fifo              (read_fifo),
        .fifo_empty             (fifo_empty),
        .fifo_almost_empty      (fifo_almost_empty),
        .overflow               (overflow),
        .underflow              (underflow),
        .rd_en_out              (rd_en_out)
    );

endmodule
