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

import pcie_intf_pkg::*;
import pcie_str_pkg::*;
import pcie_rp_pkg::*;
import ps_param_pkg::*;


module rp_top #(
    parameter RP_CTRL0                  = ps_param_pkg::RP_CTRL0,
    parameter RP_CTRL1                  = ps_param_pkg::RP_CTRL1,
    parameter NUM_BAR                   = pcie_rp_pkg::NUM_BAR,
    parameter EP_ROM_SIZE               = pcie_rp_pkg::EP_ROM_SIZE,
    parameter RP_ROM_SIZE               = pcie_rp_pkg::RP_ROM_SIZE,
    parameter TRAFFIC_COUNT             = pcie_rp_pkg::TRAFFIC_COUNT,
    parameter MAX_PAYLOAD_SIZE          = pcie_rp_pkg::MAX_PAYLOAD_SIZE,
    parameter ENABLE_EXTENDED_TAG       = pcie_rp_pkg::ENABLE_EXTENDED_TAG,
    parameter ADDR_WIDTH                = pcie_rp_pkg::ADDR_WIDTH,
    parameter DATA_WIDTH                = pcie_rp_pkg::DATA_WIDTH,
    parameter DW_SIZE                   = pcie_rp_pkg::DW_SIZE,
    parameter ADDR_BUF_DEPTH            = pcie_rp_pkg::ADDR_BUF_DEPTH,
    parameter TX_CREDIT_NUM             = pcie_rp_pkg::TX_CREDIT_NUM, // Max TX credits at a time
    parameter MAX_PAYLOAD_SIZE_BYTE     = pcie_rp_pkg::MAX_PAYLOAD_SIZE_BYTE, // Maximum payload size in bytes
    parameter CHECKER_DATA_WIDTH        = pcie_rp_pkg::CHECKER_DATA_WIDTH,
    parameter CHECKER_ADDR_WIDTH        = pcie_rp_pkg::CHECKER_ADDR_WIDTH,
    parameter LOWER_ADDR_WIDTH          = pcie_rp_pkg::LOWER_ADDR_WIDTH,
    parameter ERROR_CNT_WIDTH           = pcie_rp_pkg::ERROR_CNT_WIDTH,
    parameter NUM_VFS                   = pcie_rp_pkg::NUM_VFS,
    parameter NUM_PFS                   = pcie_rp_pkg::NUM_PFS,
    parameter PLDBI_ADDR_WIDTH          = pcie_rp_pkg::PLDBI_ADDR_WIDTH,
    parameter PLDBI_DATA_WIDTH          = pcie_rp_pkg::PLDBI_DATA_WIDTH,
    parameter PLDBI_AUSER               = pcie_rp_pkg::PLDBI_AUSER,
    parameter PLDBI_RESP_USER           = pcie_rp_pkg::PLDBI_RESP_USER,
    parameter ACTUAL_PAYLOAD_SIZE_BYTE  = pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE,
    parameter IDE_EN                    = 0, // 1: AXI config bridge + hold traffic until an IDE stream is Secure
    parameter logic [11:0] IDE_CAP_OFFSET = 12'h000 // RP config-space offset of the IDE extended capability
)(
    input logic clk,
    input logic rst_n,
    input logic [7:0] link_down,

    input  logic                                                                        rx_valid,
    input  logic    [(pcie_str_pkg::RX_SLOT_WIDTH*pcie_str_pkg::MAX_NUM_SLOTS)-1:0]     rx_data,
    input  logic    [pcie_str_pkg::RX_PARITY_WIDTH-1:0]                                 rx_parity,
    input  logic    [pcie_str_pkg::MAX_NUM_SLOTS-1:0]                                   rx_start,
    input  logic    [pcie_str_pkg::START_PTR_WIDTH-1:0]                                 rx_start0ptr,
    input  logic    [pcie_str_pkg::START_PTR_WIDTH-1:0]                                 rx_start1ptr,
    input  logic    [pcie_str_pkg::START_PTR_WIDTH-1:0]                                 rx_start2ptr,
    input  logic    [pcie_str_pkg::START_TYPE_WIDTH-1:0]                                rx_start0type,
    input  logic    [pcie_str_pkg::START_TYPE_WIDTH-1:0]                                rx_start1type,
    input  logic    [pcie_str_pkg::START_TYPE_WIDTH-1:0]                                rx_start2type,
    input  logic    [pcie_str_pkg::START_NP_INFO_WIDTH-1:0]                             rx_start0npinfo,
    input  logic    [pcie_str_pkg::START_NP_INFO_WIDTH-1:0]                             rx_start1npinfo,
    input  logic    [pcie_str_pkg::START_NP_INFO_WIDTH-1:0]                             rx_start2npinfo,
    input  logic    [pcie_str_pkg::MAX_NUM_SLOTS-1:0]                                   rx_end,
    input  logic    [pcie_str_pkg::END_PTR_WIDTH+pcie_str_pkg::END_DPTR_WIDTH-1:0]      rx_end0ptr,
    input  logic    [pcie_str_pkg::END_PTR_WIDTH+pcie_str_pkg::END_DPTR_WIDTH-1:0]      rx_end1ptr,
    input  logic    [pcie_str_pkg::END_PTR_WIDTH+pcie_str_pkg::END_DPTR_WIDTH-1:0]      rx_end2ptr,
    input  logic    [pcie_str_pkg::END_ERROR_WIDTH-1:0]                                 rx_end_err,

    input  logic                                                                        tx_credit_valid,
    input  logic    [2:0]                                                               tx_credit,

    output logic                                                                        tx_credit_active,

    output  logic                                                                       rx_credit_valid,
    output  logic   [2:0]                                                               rx_credit,
    input   logic                                                                       rx_credit_active,

    output logic                                                                        tx_valid,
    output  logic    [(pcie_str_pkg::TX_SLOT_WIDTH*pcie_str_pkg::MAX_NUM_SLOTS)-1:0]    tx_data,
    output  logic    [pcie_str_pkg::TX_PARITY_WIDTH-1:0]                                tx_parity,
    output  logic    [pcie_str_pkg::MAX_NUM_SLOTS-1:0]                                  tx_start,
    output  logic    [pcie_str_pkg::START_PTR_WIDTH-1:0]                                tx_start0ptr,
    output  logic    [pcie_str_pkg::START_PTR_WIDTH-1:0]                                tx_start1ptr,
    output  logic    [pcie_str_pkg::START_PTR_WIDTH-1:0]                                tx_start2ptr,
    output  logic    [pcie_str_pkg::START_TYPE_WIDTH-1:0]                               tx_start0type,
    output  logic    [pcie_str_pkg::START_TYPE_WIDTH-1:0]                               tx_start1type,
    output  logic    [pcie_str_pkg::START_TYPE_WIDTH-1:0]                               tx_start2type,
    output  logic    [pcie_str_pkg::START_NP_INFO_WIDTH-1:0]                            tx_start0npinfo,
    output  logic    [pcie_str_pkg::START_NP_INFO_WIDTH-1:0]                            tx_start1npinfo,
    output  logic    [pcie_str_pkg::START_NP_INFO_WIDTH-1:0]                            tx_start2npinfo,
    output  logic    [pcie_str_pkg::MAX_NUM_SLOTS-1:0]                                  tx_end,
    output  logic    [pcie_str_pkg::END_PTR_WIDTH+pcie_str_pkg::END_DPTR_WIDTH-1:0]     tx_end0ptr,
    output  logic    [pcie_str_pkg::END_PTR_WIDTH+pcie_str_pkg::END_DPTR_WIDTH-1:0]     tx_end1ptr,
    output  logic    [pcie_str_pkg::END_PTR_WIDTH+pcie_str_pkg::END_DPTR_WIDTH-1:0]     tx_end2ptr,
    output  logic    [pcie_str_pkg::END_ERROR_WIDTH-1:0]                                tx_end_error,



    // PCIe Configuration Status Interface
    input  logic                                                                        pf_cfg_status_pvld,
    input  logic [15:0]                                                                 pf_cfg_status_info,
    input  logic                                                                        pf_cfg_status_sos,
    input  logic [2:0]                                                                  pf_cfg_status_func_num,

    input  logic                                                                        vf_cfg_status_pvld,
    input  logic [15:0]                                                                 vf_cfg_status_info,
    input  logic                                                                        vf_cfg_status_sos,
    input  logic [7:0]                                                                  vf_cfg_status_func_num,

    // RP CONFIG Status to PL
    output  logic [PLDBI_ADDR_WIDTH-1:0]                                                pl_dbi_axil_if_awaddr,
    input   logic                                                                       pl_dbi_axil_if_awready,
    output  logic                                                                       pl_dbi_axil_if_awvalid,
    output  logic [PLDBI_AUSER-1:0]                                                     pl_dbi_axil_if_awuser,
    output  logic [2:0]                                                                 pl_dbi_axil_if_awprot,
    output  logic [PLDBI_ADDR_WIDTH-1:0]                                                pl_dbi_axil_if_araddr,
    input   logic                                                                       pl_dbi_axil_if_arready,
    output  logic                                                                       pl_dbi_axil_if_arvalid,
    output  logic [PLDBI_AUSER-1:0]                                                     pl_dbi_axil_if_aruser,
    output  logic [2:0]                                                                 pl_dbi_axil_if_arprot,
    output  logic [PLDBI_DATA_WIDTH-1:0]                                                pl_dbi_axil_if_wdata,
    output  logic [PLDBI_DATA_WIDTH/8-1:0]                                              pl_dbi_axil_if_wuser,
    output  logic [PLDBI_DATA_WIDTH/8-1:0]                                              pl_dbi_axil_if_wstrb,
    input   logic                                                                       pl_dbi_axil_if_wready,
    output  logic                                                                       pl_dbi_axil_if_wvalid,
    input   logic [PLDBI_DATA_WIDTH-1:0]                                                pl_dbi_axil_if_rdata,
    input   logic [1:0]                                                                 pl_dbi_axil_if_rresp,
    input   logic [PLDBI_DATA_WIDTH/8-1:0]                                              pl_dbi_axil_if_ruser,
    output  logic                                                                       pl_dbi_axil_if_rready,
    input   logic                                                                       pl_dbi_axil_if_rvalid,
    input   logic [1:0]                                                                 pl_dbi_axil_if_bresp,
    input   logic [PLDBI_RESP_USER-1:0]                                                 pl_dbi_axil_if_buser,
    output  logic                                                                       pl_dbi_axil_if_bready,
    input   logic                                                                       pl_dbi_axil_if_bvalid,
    // AXI4-Lite slave: PCIe config access bridge (M00_AXI_0 of the BD). IDE_EN=1 only; tied off otherwise.
    input   logic [41:0]                                                                cfg_axil_awaddr,
    input   logic [2:0]                                                                 cfg_axil_awprot,
    input   logic                                                                       cfg_axil_awvalid,
    output  logic                                                                       cfg_axil_awready,
    input   logic [31:0]                                                                cfg_axil_wdata,
    input   logic [3:0]                                                                 cfg_axil_wstrb,
    input   logic                                                                       cfg_axil_wvalid,
    output  logic                                                                       cfg_axil_wready,
    output  logic [1:0]                                                                 cfg_axil_bresp,
    output  logic                                                                       cfg_axil_bvalid,
    input   logic                                                                       cfg_axil_bready,
    input   logic [41:0]                                                                cfg_axil_araddr,
    input   logic [2:0]                                                                 cfg_axil_arprot,
    input   logic                                                                       cfg_axil_arvalid,
    output  logic                                                                       cfg_axil_arready,
    output  logic [31:0]                                                                cfg_axil_rdata,
    output  logic [1:0]                                                                 cfg_axil_rresp,
    output  logic                                                                       cfg_axil_rvalid,
    input   logic                                                                       cfg_axil_rready,
    output  logic   [3:0]                                                               dbg_state
);
    localparam TAG_COUNT = ENABLE_EXTENDED_TAG ? 256 : 32; // Use extended tag count if enabled
    localparam ACTUAL_PAYLOAD_SIZE_SLOT = ACTUAL_PAYLOAD_SIZE_BYTE <= 64 ? 1 : 2; // 0-64B payload then 1 slot 65-128B payload then 2 slot
    localparam CHECKER_DEPTH = TAG_COUNT;
    // Configuration Status Signals
    logic [NUM_PFS-1:0]             cfg_bus_master_en;
    logic [NUM_PFS-1:0]             cfg_mem_space_en;
    logic [NUM_PFS-1:0]             cfg_msi_en;
    logic [NUM_PFS-1:0]             cfg_msix_en;
    logic [NUM_PFS-1:0]             cfg_msix_func_mask;
    logic [NUM_PFS-1:0]             cfg_pf_pasid_en;
    logic [NUM_PFS-1:0]             cfg_atomic_req_en;
    logic [NUM_PFS-1:0][2:0]        cfg_max_rd_req_size;
    logic [NUM_PFS-1:0][2:0]        cfg_max_payload_size;
    logic [NUM_PFS-1:0]             cfg_ext_tag_en;
    logic [NUM_PFS-1:0]             cfg_rcb;
    logic [NUM_PFS-1:0]             cfg_flr_pf_active;
    logic [NUM_PFS-1:0]             cfg_10b_tag_req_en;
    logic [NUM_PFS-1:0]             cfg_vf_en;
    logic [NUM_PFS-1:0]             cfg_int_disable;
    logic [NUM_PFS-1:0]             pm_status;
    logic [NUM_PFS-1:0]             cfg_io_space_en;
    logic [NUM_PFS-1:0]             cfg_pf_pasid_execute_perm_en;
    logic [NUM_PFS-1:0]             cfg_pf_pasid_priv_mode_en;
    logic [NUM_PFS-1:0]             cfg_ats_cache_en;
    logic [NUM_PFS-1:0]             cfg_prs_enable;
    logic [NUM_PFS-1:0][1:0]        cfg_tph_req_en;
    logic [NUM_PFS-1:0]             radm_pm_turnoff;
    logic [NUM_PFS-1:0]             cfg_pcie_cap_flit_mode_stat;

    logic [NUM_VFS-1:0]             cfg_vf_bme;
    logic [NUM_VFS-1:0]             cfg_vf_msi_en;
    logic [NUM_VFS-1:0]             cfg_vf_msix_en;
    logic [NUM_VFS-1:0]             cfg_vf_msix_func_mask;
    logic [NUM_VFS-1:0]             cfg_flr_vf_active;

    logic [15:0]                    cfg_mismatch_error_count;
    logic                           rp_cfg_cpl_valid;

    // Signals for `config_mem_handler`
    logic                            completion_received;
    logic                            ep_completion_received;
    logic [31:0]                     cpl_data;
    logic                            req_ready;
    logic [$clog2(TAG_COUNT)-1:0]    tag_id;
    logic                            tag_valid;
    logic [$clog2(TAG_COUNT):0] free_tag_count;
    rp_cfg_intf                      rp_cfg;
    logic [15:0]                     ep_cfg_count;
    logic                            rp_rom_config_done;
    logic                            overall_rp_config_done;
    logic                            ep_config_match;
    tx_pkt_intf [pcie_str_pkg::TX_NUM_SLOTS-1:0]        tx_pkt_data_reg2;
    logic                              final_req_valid;
    logic [1:0]                        final_req_count;

    logic [$clog2(TAG_COUNT)-1:0]      tag_to_match;
    logic                              bar_read_done;
    logic                              rp_start_reg;

    // Signals for `packet_generation`
    tx_pkt_intf [pcie_str_pkg::TX_NUM_SLOTS-1:0]        tx_pkt_data;
    tx_intf                            tx_if;
    logic [3:0]                        payload_end_byte; // End byte for payload

    assign payload_end_byte = (ACTUAL_PAYLOAD_SIZE_BYTE - 1) >> 2; // DW alignment for end byte
    assign completion_received = rp_start_reg ? rp_cfg_cpl_valid : ep_completion_received; 

    // Signals for `completor`

    rx_intf                           rx_if;

    // Signals for `cpl_checker`
    logic                                                        mem_checker_ram_rd_en;
    logic        [$clog2(CHECKER_DEPTH)-1:0]                     mem_checker_ram_rd_addr;
    logic        [CHECKER_DATA_WIDTH + CHECKER_ADDR_WIDTH - 1:0] mem_checker_ram_rd_data;
    logic                                                        mem_checker_ram_wr_en;
    logic        [$clog2(CHECKER_DEPTH)-1:0]                     mem_checker_ram_wr_addr;
    logic        [CHECKER_DATA_WIDTH + CHECKER_ADDR_WIDTH - 1:0] mem_checker_ram_wr_data;
    
    logic                                                        cfg_checker_ram_rd_en;
    logic        [$clog2(CHECKER_DEPTH)-1:0]                     cfg_checker_ram_rd_addr;
    logic        [CHECKER_DATA_WIDTH - 1:0]                      cfg_checker_ram_rd_data;
    logic                                                        cfg_checker_ram_wr_en;
    logic        [$clog2(CHECKER_DEPTH)-1:0]                     cfg_checker_ram_wr_addr;
    logic        [CHECKER_DATA_WIDTH - 1:0]                      cfg_checker_ram_wr_data;

    logic        [(pcie_str_pkg::RX_NUM_SLOTS)-1:0]            credits_to_return;

    logic                              free_valid;
    logic [$clog2(TAG_COUNT)-1:0]      free_tag_1;


    // Signals for `tx_credit_handler`

    logic [(pcie_str_pkg::TX_NUM_SLOTS)-1:0]      tx_credit_used;
    logic                              tx_credit_available;
    logic halt;
    logic                              is_flitmode; 

    error_counters_t                    error_counts;

    pl_dbi_axil_if #(.DATA_WIDTH(PLDBI_DATA_WIDTH), .ADDR_WIDTH(PLDBI_ADDR_WIDTH), .AUSER(PLDBI_AUSER), .RESP_USER(PLDBI_RESP_USER)) pl_dbi_axil_if_reg();

    assign halt = !tx_credit_available;
    assign is_flitmode = cfg_pcie_cap_flit_mode_stat[0]; // PF 0 Flitmode

    always_comb begin
       pl_dbi_axil_if_awaddr = pl_dbi_axil_if_reg.awaddr;
       pl_dbi_axil_if_reg.awready = pl_dbi_axil_if_awready ;
       pl_dbi_axil_if_awvalid = pl_dbi_axil_if_reg.awvalid;
       pl_dbi_axil_if_awuser = pl_dbi_axil_if_reg.awuser;
       pl_dbi_axil_if_awprot = pl_dbi_axil_if_reg.awprot;
       pl_dbi_axil_if_araddr = pl_dbi_axil_if_reg.araddr;
       pl_dbi_axil_if_reg.arready = pl_dbi_axil_if_arready ;
       pl_dbi_axil_if_arvalid = pl_dbi_axil_if_reg.arvalid;
       pl_dbi_axil_if_aruser = pl_dbi_axil_if_reg.aruser;
       pl_dbi_axil_if_arprot = pl_dbi_axil_if_reg.arprot;
       pl_dbi_axil_if_wdata = pl_dbi_axil_if_reg.wdata;
       pl_dbi_axil_if_wuser = pl_dbi_axil_if_reg.wuser;
       pl_dbi_axil_if_wstrb = pl_dbi_axil_if_reg.wstrb;
       pl_dbi_axil_if_reg.wready = pl_dbi_axil_if_wready ;
       pl_dbi_axil_if_wvalid = pl_dbi_axil_if_reg.wvalid;
       pl_dbi_axil_if_reg.rdata = pl_dbi_axil_if_rdata ;
       pl_dbi_axil_if_reg.rresp = pl_dbi_axil_if_rresp ;
       pl_dbi_axil_if_reg.ruser = pl_dbi_axil_if_ruser ;
       pl_dbi_axil_if_rready = pl_dbi_axil_if_reg.rready;
       pl_dbi_axil_if_reg.rvalid = pl_dbi_axil_if_rvalid ;
       pl_dbi_axil_if_reg.bresp = pl_dbi_axil_if_bresp ;
       pl_dbi_axil_if_reg.buser = pl_dbi_axil_if_buser ;
       pl_dbi_axil_if_bready = pl_dbi_axil_if_reg.bready;
       pl_dbi_axil_if_reg.bvalid = pl_dbi_axil_if_bvalid ;
    end

    always_comb begin
        tx_valid = tx_if.tx_valid;
        tx_data = {tx_if.tx_data[2], tx_if.tx_data[1], tx_if.tx_data[0]};
        tx_parity = tx_if.tx_parity;
        tx_start = tx_if.tx_start;
        tx_start0ptr = tx_if.tx_startptr[0];
        tx_start1ptr = tx_if.tx_startptr[1];
        tx_start2ptr = tx_if.tx_startptr[2];
        tx_start0type = tx_if.tx_starttype[0];
        tx_start1type = tx_if.tx_starttype[1];
        tx_start2type = tx_if.tx_starttype[2];
        tx_start0npinfo = tx_if.tx_startnpinfo[0];
        tx_start1npinfo = tx_if.tx_startnpinfo[1];
        tx_start2npinfo = tx_if.tx_startnpinfo[2];
        tx_end = tx_if.tx_end;
        tx_end0ptr = tx_if.tx_endptr[0];
        tx_end1ptr = tx_if.tx_endptr[1];
        tx_end2ptr = tx_if.tx_endptr[2];
        tx_end_error = tx_if.tx_end_error;
    end

    always_comb begin
        rx_if.rx_valid = rx_valid;
        rx_if.rx_data           = {
            {{(RX_SLOT_WIDTH - 512){1'b0}}, rx_data[1535:1024]},
            {{(RX_SLOT_WIDTH - 512){1'b0}}, rx_data[1023:512]},
            {{(RX_SLOT_WIDTH - 512){1'b0}}, rx_data[511:0]}
        };
        rx_if.rx_parity = rx_parity;
        rx_if.rx_start = rx_start;
        rx_if.rx_startptr[0] = rx_start0ptr;
        rx_if.rx_startptr[1] = rx_start1ptr;
        rx_if.rx_startptr[2] = rx_start2ptr;
        rx_if.rx_starttype[0] = rx_start0type;
        rx_if.rx_starttype[1] = rx_start1type;
        rx_if.rx_starttype[2] = rx_start2type;
        rx_if.rx_startnpinfo[0] = rx_start0npinfo;
        rx_if.rx_startnpinfo[1] = rx_start1npinfo;
        rx_if.rx_startnpinfo[2] = rx_start2npinfo;
        rx_if.rx_end = rx_end;
        rx_if.rx_endptr[0] = rx_end0ptr;
        rx_if.rx_endptr[1] = rx_end1ptr;
        rx_if.rx_endptr[2] = rx_end2ptr;
        rx_if.rx_end_error = rx_end_err;
    end

    // Traffic start (IDE_EN=1): rp_config_handler polls the RP IDE capability and
    // reports when any Link/Selective IDE stream is Secure. Not latched: a link-down
    // restarts RP config and the poll, so traffic waits for the stream again.
    logic traffic_go;
    logic ide_secure;
    logic ide_cap_missing;
    assign traffic_go = IDE_EN ? ide_secure : 1'b1;

    // AXI4-Lite config bridge <-> config_mem_handler
    logic        axi_req_valid, axi_req_wr, axi_req_accept, axi_req_done, axi_busy;
    logic axi_cfg_ready;
    logic [31:0] axi_req_addr, axi_req_wdata;

    generate
        if (IDE_EN) begin : g_cfg_bridge
        axil_cfg_bridge #(
            .ADDR_WIDTH (42)
        ) axil_cfg_bridge_inst (
            .clk            (clk),
            .rst_n          (rst_n),
            .link_down      (link_down[0]),
            .awaddr         (cfg_axil_awaddr),
            .awprot         (cfg_axil_awprot),
            .awvalid        (cfg_axil_awvalid),
            .awready        (cfg_axil_awready),
            .wdata          (cfg_axil_wdata),
            .wstrb          (cfg_axil_wstrb),
            .wvalid         (cfg_axil_wvalid),
            .wready         (cfg_axil_wready),
            .bresp          (cfg_axil_bresp),
            .bvalid         (cfg_axil_bvalid),
            .bready         (cfg_axil_bready),
            .araddr         (cfg_axil_araddr),
            .arprot         (cfg_axil_arprot),
            .arvalid        (cfg_axil_arvalid),
            .arready        (cfg_axil_arready),
            .rdata          (cfg_axil_rdata),
            .rresp          (cfg_axil_rresp),
            .rvalid         (cfg_axil_rvalid),
            .rready         (cfg_axil_rready),
            .cfg_ready      (axi_cfg_ready),
            .req_valid      (axi_req_valid),
            .req_wr         (axi_req_wr),
            .req_addr       (axi_req_addr),
            .req_wdata      (axi_req_wdata),
            .req_accept     (axi_req_accept),
            .req_done       (axi_req_done),
            .busy           (axi_busy),
            .cpl_data_valid (ep_completion_received),
            .cpl_data       (cpl_data),
            .cpl_hdr_valid  (free_valid)
        );

        end else begin : g_no_cfg_bridge
            // No bridge: AXI4-Lite slave never accepts (any master access will stall)
            assign cfg_axil_awready = 1'b0;
            assign cfg_axil_wready  = 1'b0;
            assign cfg_axil_bvalid  = 1'b0;
            assign cfg_axil_bresp   = 2'b00;
            assign cfg_axil_arready = 1'b0;
            assign cfg_axil_rvalid  = 1'b0;
            assign cfg_axil_rdata   = '0;
            assign cfg_axil_rresp   = 2'b00;
            assign axi_req_valid    = 1'b0;
            assign axi_req_wr       = 1'b0;
            assign axi_req_addr     = '0;
            assign axi_req_wdata    = '0;
            assign axi_req_done     = 1'b0;
            assign axi_busy         = 1'b0;
        end
    endgenerate

    // ---------------------------------------------------------------
    // Debug: traffic activity and error counters
    // ---------------------------------------------------------------
    logic [31:0] dbg_tx_p_cnt;       // posted TLP starts sent (mem writes)
    logic [31:0] dbg_tx_np_cnt;      // non-posted TLP starts sent (reads, cfg)
    logic [31:0] dbg_rx_cpl_cnt;     // completions received (tags freed)
    logic [15:0] dbg_dbi_ar_cnt;     // PL DBI read addresses accepted
    logic [15:0] dbg_dbi_r_cnt;      // PL DBI read data returned
    logic [15:0] dbg_dbi_aw_cnt;     // PL DBI write addresses accepted
    logic [15:0] dbg_dbi_b_cnt;      // PL DBI write responses returned
    logic [1:0] dbg_p_add, dbg_np_add;

    always_comb begin
        dbg_p_add  = '0;
        dbg_np_add = '0;
        if (tx_valid) begin
            if (tx_start[0]) begin if (tx_start0type[0]) dbg_np_add = dbg_np_add + 1'b1; else dbg_p_add = dbg_p_add + 1'b1; end
            if (tx_start[1]) begin if (tx_start1type[0]) dbg_np_add = dbg_np_add + 1'b1; else dbg_p_add = dbg_p_add + 1'b1; end
            if (tx_start[2]) begin if (tx_start2type[0]) dbg_np_add = dbg_np_add + 1'b1; else dbg_p_add = dbg_p_add + 1'b1; end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dbg_tx_p_cnt     <= '0;
            dbg_tx_np_cnt    <= '0;
            dbg_rx_cpl_cnt   <= '0;
            dbg_dbi_ar_cnt   <= '0;
            dbg_dbi_r_cnt    <= '0;
            dbg_dbi_aw_cnt   <= '0;
            dbg_dbi_b_cnt    <= '0;
        end else begin
            if (pl_dbi_axil_if_arvalid && pl_dbi_axil_if_arready) dbg_dbi_ar_cnt <= dbg_dbi_ar_cnt + 1'b1;
            if (pl_dbi_axil_if_rvalid  && pl_dbi_axil_if_rready)  dbg_dbi_r_cnt  <= dbg_dbi_r_cnt  + 1'b1;
            if (pl_dbi_axil_if_awvalid && pl_dbi_axil_if_awready) dbg_dbi_aw_cnt <= dbg_dbi_aw_cnt + 1'b1;
            if (pl_dbi_axil_if_bvalid  && pl_dbi_axil_if_bready)  dbg_dbi_b_cnt  <= dbg_dbi_b_cnt  + 1'b1;
            dbg_tx_p_cnt   <= dbg_tx_p_cnt  + dbg_p_add;
            dbg_tx_np_cnt  <= dbg_tx_np_cnt + dbg_np_add;
            if (free_valid)
                dbg_rx_cpl_cnt <= dbg_rx_cpl_cnt + 1'b1;
        end
    end

    // Error counters (completion checker), individually visible to the debug core
    logic [15:0] dbg_err_addr_mismatch;
    logic [15:0] dbg_err_data_mismatch;
    logic [15:0] dbg_err_fmt_mismatch;
    logic [15:0] dbg_err_ttype_mismatch;
    logic [15:0] dbg_err_ur;
    logic [15:0] dbg_err_ca;
    logic [15:0] dbg_err_cfg_retry;
    logic [15:0] dbg_err_abort;
    logic [15:0] dbg_err_poisoned;
    assign dbg_err_addr_mismatch  = error_counts.addr_mismatch_cnt;
    assign dbg_err_data_mismatch  = error_counts.data_mismatch_cnt;
    assign dbg_err_fmt_mismatch   = error_counts.fmt_mismatch_cnt;
    assign dbg_err_ttype_mismatch = error_counts.ttype_mismatch_cnt;
    assign dbg_err_ur             = error_counts.URs_cnt;
    assign dbg_err_ca             = error_counts.CAs_cnt;
    assign dbg_err_cfg_retry      = error_counts.cfg_retry_err_cnt;
    assign dbg_err_abort          = error_counts.tlp_or_dllp_abort_err_cnt;
    assign dbg_err_poisoned       = error_counts.tlp_poisoned_cnt;

    // PCIe Configuration Handler
    rp_config_handler #(
        .RP_CTRL0    (RP_CTRL0),
        .RP_CTRL1    (RP_CTRL1),
        .ADDR_WIDTH  (PLDBI_ADDR_WIDTH),
        .DATA_WIDTH  (PLDBI_DATA_WIDTH),
        .AUSER       (PLDBI_AUSER),
        .RESP_USER   (PLDBI_RESP_USER),
        .NUM_VFS     (NUM_VFS),
        .NUM_PFS     (NUM_PFS),
        .EXTENDED_TAG_EN(ENABLE_EXTENDED_TAG),
        .IDE_EN      (IDE_EN),
        .IDE_CAP_OFFSET (IDE_CAP_OFFSET)
    ) rp_config_handler_inst (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .link_down              (link_down[0]),

        // Config interface
        .rp_cfg                 (rp_cfg),
        .pl_dbi_axil_if         (pl_dbi_axil_if_reg),

        // PF Config Status
        .pf_cfg_status_pvld     (pf_cfg_status_pvld),
        .pf_cfg_status_info     (pf_cfg_status_info),
        .pf_cfg_status_sos      (pf_cfg_status_sos),
        .pf_cfg_status_func_num (pf_cfg_status_func_num),

        // VF Config Status
        .vf_cfg_status_pvld     (vf_cfg_status_pvld),
        .vf_cfg_status_info     (vf_cfg_status_info),
        .vf_cfg_status_sos      (vf_cfg_status_sos),
        .vf_cfg_status_func_num (vf_cfg_status_func_num),

        .rp_rom_config_done     (rp_rom_config_done),

        // PF Status Outputs
        .cfg_bus_master_en      (cfg_bus_master_en),
        .cfg_mem_space_en       (cfg_mem_space_en),
        .cfg_msi_en             (cfg_msi_en),
        .cfg_msix_en            (cfg_msix_en),
        .cfg_msix_func_mask     (cfg_msix_func_mask),
        .cfg_pf_pasid_en        (cfg_pf_pasid_en),
        .cfg_atomic_req_en      (cfg_atomic_req_en),
        .cfg_max_rd_req_size    (cfg_max_rd_req_size),
        .cfg_max_payload_size   (cfg_max_payload_size),
        .cfg_ext_tag_en         (cfg_ext_tag_en),
        .cfg_rcb                (cfg_rcb),
        .cfg_flr_pf_active      (cfg_flr_pf_active),
        .cfg_10b_tag_req_en     (cfg_10b_tag_req_en),
        .cfg_vf_en              (cfg_vf_en),
        .cfg_int_disable        (cfg_int_disable),
        .pm_status              (pm_status),
        .cfg_io_space_en        (cfg_io_space_en),
        .cfg_pf_pasid_execute_perm_en (cfg_pf_pasid_execute_perm_en),
        .cfg_pf_pasid_priv_mode_en (cfg_pf_pasid_priv_mode_en),
        .cfg_ats_cache_en       (cfg_ats_cache_en),
        .cfg_prs_enable         (cfg_prs_enable),
        .cfg_tph_req_en         (cfg_tph_req_en),
        .radm_pm_turnoff        (radm_pm_turnoff),
        .cfg_pcie_cap_flit_mode_stat (cfg_pcie_cap_flit_mode_stat),

        // VF Status Outputs
        .cfg_vf_bme             (cfg_vf_bme),
        .cfg_vf_msi_en          (cfg_vf_msi_en),
        .cfg_vf_msix_en         (cfg_vf_msix_en),
        .cfg_vf_msix_func_mask  (cfg_vf_msix_func_mask),
        .cfg_flr_vf_active      (cfg_flr_vf_active),

        // Output completion
        .cfg_cpl_valid          (rp_cfg_cpl_valid),
        .cfg_mismatch_error_count (cfg_mismatch_error_count),

        .overall_rp_config_done (overall_rp_config_done),
        .ide_secure             (ide_secure),
        .ide_cap_missing        (ide_cap_missing)
    );

    // Instantiate `config_mem_handler`
    config_mem_handler #(
        .RP_CTRL0         (RP_CTRL0),
        .RP_CTRL1         (RP_CTRL1),
        .NUM_BAR          (NUM_BAR),
        .NUM_SLOTS        (TX_NUM_SLOTS),
        .MAX_NUM_SLOTS    (MAX_NUM_SLOTS),
        .EP_ROM_SIZE      (EP_ROM_SIZE),
        .RP_ROM_SIZE      (RP_ROM_SIZE),
        .TRAFFIC_COUNT    (TRAFFIC_COUNT),
        .MAX_PAYLOAD_SIZE (MAX_PAYLOAD_SIZE),
        .TAG_COUNT        (TAG_COUNT),
        .ADDR_WIDTH       (ADDR_WIDTH),
        .DATA_WIDTH       (DATA_WIDTH),
        .DW_SIZE          (DW_SIZE),
        .ADDR_BUF_DEPTH   (ADDR_BUF_DEPTH),
        .MAX_PAYLOAD_SIZE_BYTE (MAX_PAYLOAD_SIZE_BYTE),
        .LOWER_ADDR_WIDTH  (CHECKER_ADDR_WIDTH),
        .ACTUAL_PAYLOAD_SIZE_SLOT (ACTUAL_PAYLOAD_SIZE_SLOT),
        .ACTUAL_PAYLOAD_SIZE_BYTE (ACTUAL_PAYLOAD_SIZE_BYTE),
        .IDE_EN           (IDE_EN)
    ) config_mem_handler_inst (
        .clk                  (clk),
        .rst_n                (rst_n),
        .link_down            (link_down[1]),
        .halt                 (halt),
        .completion_received  (completion_received),
        .cpl_data             (cpl_data),
        .req_ready            (req_ready),
        .tag_id               (tag_id),
        .tag_valid            (tag_valid),
        .free_tag_count       (free_tag_count),
        .tx_pkt_data_reg2     (tx_pkt_data_reg2),
        .final_req_valid      (final_req_valid),
        .final_req_count      (final_req_count),
        .mem_checker_wr_addr  (mem_checker_ram_wr_addr),
        .mem_checker_wr_data  (mem_checker_ram_wr_data),
        .mem_checker_wr_en    (mem_checker_ram_wr_en),
        .cfg_checker_wr_addr  (cfg_checker_ram_wr_addr),
        .cfg_checker_wr_data  (cfg_checker_ram_wr_data),
        .cfg_checker_wr_en    (cfg_checker_ram_wr_en),
        .rp_cfg_data          (rp_cfg),
        .rp_rom_config_done   (rp_rom_config_done),
        .overall_rp_config_done (overall_rp_config_done),
        .traffic_go           (traffic_go),
        .axi_req_valid        (axi_req_valid),
        .axi_req_wr           (axi_req_wr),
        .axi_req_addr         (axi_req_addr),
        .axi_req_wdata        (axi_req_wdata),
        .axi_req_accept       (axi_req_accept),
        .axi_req_done         (axi_req_done),
        .axi_cfg_ready        (axi_cfg_ready),
        .ep_total_config_count (ep_cfg_count),
        .ep_config_match      (ep_config_match),
        .tag_to_match         (tag_to_match),
        .bar_read_done        (bar_read_done),
        .dbg_state        (dbg_state),
        .rp_start_reg         (rp_start_reg)
    );

    // Instantiate `packet_generation`
    packet_generation #(
        .NUM_SLOTS        (TX_NUM_SLOTS),
        .FUNC_NUM         (0),
        .VFUNC_NUM        (0),
        .VFUNC_ACTIVE     (0),
        .TX_SLOT_WIDTH    (TX_SLOT_WIDTH),
        .DW_SIZE          (DW_SIZE),
        .MAX_PAYLOAD_SIZE (MAX_PAYLOAD_SIZE),
        .ACTUAL_PAYLOAD_SIZE_SLOT (ACTUAL_PAYLOAD_SIZE_SLOT),
        .ACTUAL_PAYLOAD_SIZE_BYTE (ACTUAL_PAYLOAD_SIZE_BYTE)
    ) packet_generation_inst (
        .clk              (clk),
        .rst_n            (rst_n),
        .link_down        (link_down[2]),
        .halt             (halt),
        .tx_pkt_data      (tx_pkt_data_reg2),
        .is_flitmode      (is_flitmode),
        .payload_end_byte (payload_end_byte),
        .tx_if            (tx_if),
        .tx_credit_used   (tx_credit_used)
    );

    completor_wrapper #(
        .NUM_SLOTS        (RX_NUM_SLOTS),
        .MAX_PAYLOAD_SIZE (MAX_PAYLOAD_SIZE),
        .ADDR_WIDTH       (ADDR_WIDTH),
        .DATA_WIDTH       (DATA_WIDTH),
        .CHECKER_DEPTH    (CHECKER_DEPTH),
        .CHECKER_ADDR_WIDTH (CHECKER_ADDR_WIDTH),
        .CHECKER_DATA_WIDTH (CHECKER_DATA_WIDTH),
        .ERROR_CNT_WIDTH  (ERROR_CNT_WIDTH),
        .TAG_COUNT        (TAG_COUNT),
        .ACTUAL_PAYLOAD_SIZE_SLOT (ACTUAL_PAYLOAD_SIZE_SLOT),
        .ACTUAL_PAYLOAD_SIZE_BYTE (ACTUAL_PAYLOAD_SIZE_BYTE),
        .IDE_EN           (IDE_EN)
    ) completor_wrapper_inst (
        .clk                        (clk),
        .rst_n                      (rst_n),
        .link_down                  (link_down[3]),
        .rx_if                      (rx_if),
        .cfg_checker_ram_rd_data    (cfg_checker_ram_rd_data),
        .cfg_checker_ram_rd_en      (cfg_checker_ram_rd_en),
        .cfg_checker_ram_rd_addr    (cfg_checker_ram_rd_addr),
        .mem_checker_ram_rd_data    (mem_checker_ram_rd_data),
        .mem_checker_ram_rd_en      (mem_checker_ram_rd_en),
        .mem_checker_ram_rd_addr    (mem_checker_ram_rd_addr),
        .free_tag_valid             (free_valid),
        .free_tag                   (free_tag_1),
        .credits_to_return          (credits_to_return),
        .cpl_received               (ep_completion_received),
        .cpl_to_config_mem_handler  (cpl_data),
        .error_counts               (error_counts),
        .ep_cfg_count               (ep_cfg_count),
        .ep_cfg_match               (ep_config_match),
        .tag_to_match               (tag_to_match),
        .bar_read_done              (bar_read_done & ~axi_busy) // bridge reads have no expected data
    );

    // Instantiate `checker_ram`
    checker_ram #(
        .DATA_WIDTH         (CHECKER_DATA_WIDTH),
        .ADDR_WIDTH         (CHECKER_ADDR_WIDTH),
        .CHECKER_DEPTH      (CHECKER_DEPTH)
    ) mem_checker_ram_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .link_down          (link_down[4]),
        .rd_en              (mem_checker_ram_rd_en),
        .rd_addr            (mem_checker_ram_rd_addr),
        .rd_data            (mem_checker_ram_rd_data),
        .wr_en              (mem_checker_ram_wr_en),
        .wr_addr            (mem_checker_ram_wr_addr),
        .wr_data            (mem_checker_ram_wr_data)
    );

    checker_ram #(
        .DATA_WIDTH         (CHECKER_DATA_WIDTH),
        .ADDR_WIDTH         ('0),
        .CHECKER_DEPTH      (CHECKER_DEPTH)
    ) cfg_checker_ram_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .link_down          (link_down[5]),
        .rd_en              (cfg_checker_ram_rd_en),
        .rd_addr            (cfg_checker_ram_rd_addr),
        .rd_data            (cfg_checker_ram_rd_data),
        .wr_en              (cfg_checker_ram_wr_en),
        .wr_addr            (cfg_checker_ram_wr_addr),
        .wr_data            (cfg_checker_ram_wr_data)
    );

    // Instantiate `tag_manager`
    tag_manager #(
        .TAG_COUNT          (TAG_COUNT)
    ) tag_manager_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .req_valid          (final_req_valid),
        .req_count          (final_req_count),
        .req_ready          (req_ready),
        .tag_valid          (tag_valid),
        .tag_id             (tag_id),
        .free_valid         (free_valid),
        .free_tag_1         (free_tag_1),
        .free_tag_count     (free_tag_count)
    );

    // Instantiate `tx_credit_handler`
    tx_credit_handler #(
        .TX_CREDIT_NUM      (TX_CREDIT_NUM),
        .NUM_SLOTS          (TX_NUM_SLOTS)
    ) tx_credit_handler_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .link_down          (link_down[6]),
        .tx_credit_valid    (tx_credit_valid),
        .tx_credit          (tx_credit),
        .tx_credit_used     (tx_credit_used),
        .tx_credit_active   (tx_credit_active),
        .tx_credit_available(tx_credit_available)
    );

    // Instantiate `rx_credit_handler`
    rx_credit_handler #(
        .NUM_SLOTS        (RX_NUM_SLOTS)
    ) rx_credit_handler_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .link_down          (link_down[7]),
        .credits_to_return  (credits_to_return),
        .rx_credit_valid    (rx_credit_valid),
        .rx_credit          (rx_credit),
        .rx_credit_active   (rx_credit_active)
    );

endmodule