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
import pcie_intf_pkg::*;
import ps_param_pkg::*;

module rp_config_handler #(
    parameter RP_CTRL0 = ps_param_pkg::RP_CTRL0,
    parameter RP_CTRL1 = ps_param_pkg::RP_CTRL1,
    parameter ADDR_WIDTH = 32,         // Address width
    parameter DATA_WIDTH = 32,         // Data width
    parameter AUSER = 11,              // AUSER width
    parameter RESP_USER = 4,           // Response user width
    parameter NUM_VFS = 256,          // Number of Virtual Functions
    parameter NUM_PFS = 8,             // Number of Physical Functions
    parameter EXTENDED_TAG_EN = 1,     // Extended tag enable
    parameter IDE_EN = 0,              // 1: after RP config, poll the RP IDE capability for a Secure stream
`ifdef RP_SIM_FAST
    parameter IDE_POLL_INTERVAL = 3_840,   // simulation: 10 us at 384 MHz
`else
    parameter IDE_POLL_INTERVAL = 384_000, // Cycles between IDE status sweeps (1 ms at 384 MHz)
`endif
    parameter logic [11:0] IDE_CAP_OFFSET = 12'h000 // RP config-space offset of the IDE extended capability header
)
(
    input logic                           clk,              // System clock
    input logic                           rst_n,            // Active low reset
    input logic                           link_down,        // Link down signal

    // Config interface
    input rp_cfg_intf                     rp_cfg,
    // AXI-Lite interface
    pl_dbi_axil_if.master                 pl_dbi_axil_if,       // AXI-Lite interface

    //PF Config Status
    input  logic                          pf_cfg_status_pvld,
    input  logic [15:0]                   pf_cfg_status_info,
    input  logic                          pf_cfg_status_sos,
    input  logic [2:0]                    pf_cfg_status_func_num,

    //VF Config Status
    input  logic                          vf_cfg_status_pvld,
    input  logic [15:0]                   vf_cfg_status_info,
    input  logic                          vf_cfg_status_sos,
    input  logic [7:0]                    vf_cfg_status_func_num,

    input  logic                          rp_rom_config_done,

    // PF Status Outputs
    output logic [NUM_PFS-1:0]            cfg_bus_master_en,
    output logic [NUM_PFS-1:0]            cfg_mem_space_en,
    output logic [NUM_PFS-1:0]            cfg_msi_en,
    output logic [NUM_PFS-1:0]            cfg_msix_en,
    output logic [NUM_PFS-1:0]            cfg_msix_func_mask,
    output logic [NUM_PFS-1:0]            cfg_pf_pasid_en,
    output logic [NUM_PFS-1:0]            cfg_atomic_req_en,
    output logic [NUM_PFS-1:0][2:0]       cfg_max_rd_req_size,
    output logic [NUM_PFS-1:0][2:0]       cfg_max_payload_size,
    output logic [NUM_PFS-1:0]            cfg_ext_tag_en,
    output logic [NUM_PFS-1:0]            cfg_rcb,
    output logic [NUM_PFS-1:0]            cfg_flr_pf_active,
    output logic [NUM_PFS-1:0]            cfg_10b_tag_req_en,
    output logic [NUM_PFS-1:0]            cfg_vf_en,
    output logic [NUM_PFS-1:0]            cfg_int_disable,
    output logic [NUM_PFS-1:0]            pm_status,
    output logic [NUM_PFS-1:0]            cfg_io_space_en,
    output logic [NUM_PFS-1:0]            cfg_pf_pasid_execute_perm_en,
    output logic [NUM_PFS-1:0]            cfg_pf_pasid_priv_mode_en,
    output logic [NUM_PFS-1:0]            cfg_ats_cache_en,
    output logic [NUM_PFS-1:0]            cfg_prs_enable,
    output logic [NUM_PFS-1:0][1:0]       cfg_tph_req_en,
    output logic [NUM_PFS-1:0]            radm_pm_turnoff,
    output logic [NUM_PFS-1:0]            cfg_pcie_cap_flit_mode_stat,

    // VF Status Outputs
    output logic [NUM_VFS-1:0]            cfg_vf_bme,
    output logic [NUM_VFS-1:0]            cfg_vf_msi_en,
    output logic [NUM_VFS-1:0]            cfg_vf_msix_en,
    output logic [NUM_VFS-1:0]            cfg_vf_msix_func_mask,
    output logic [NUM_VFS-1:0]            cfg_flr_vf_active,

    // Output completion
    output logic                          cfg_cpl_valid,              // Completion valid signal
    output logic [15:0]                   cfg_mismatch_error_count,
    output logic                          overall_rp_config_done,

    // IDE (IDE_EN=1 only; 0 otherwise)
    output logic                          ide_secure,       // a Link or Selective IDE stream is Secure
    output logic                          ide_cap_missing   // RP IDE extended capability not found
);

    logic [DATA_WIDTH-1:0]          cfg_cpl_data;
    logic                           cfg_rd_mismatch;
    logic [DATA_WIDTH-1:0]          cfg_expected_data_wire, cfg_expected_data_reg;
    logic                           cfg_type_wire, cfg_type_reg;
    rp_cfg_intf                     rp_cfg_wire;
    logic [DATA_WIDTH-1:0]          next_cfg_write_data;
    // Define masks for MPS configuration
    logic [DATA_WIDTH-1:0]          mps_cap_mask, mps_ctrl_mask;
    logic                           cfg_cpl_valid_wire;
    logic                           overall_rp_config_done_wire;

    // Define state machine states
    typedef enum logic [3:0] {
        RP_ROM_CONFIG       = 4'b0000,
        RP_DEV_CAP_READ     = 4'b0001,
        RP_DEV_CAP_WRITE    = 4'b0010,
        RP_DEV_CTRL_READ    = 4'b0011,
        RP_DEV_CTRL_WRITE   = 4'b0100,
        // IDE_EN only: read the RP IDE capability at IDE_CAP_OFFSET, then poll stream status
        RP_IDE_CAP          = 4'b0110,  // IDE Capability Register (base+0x04)
        RP_IDE_LINK_STS     = 4'b0111,  // Link IDE Stream Status (base+0x0C+8*i+4)
        RP_IDE_SEL_CAP      = 4'b1000,  // Selective IDE Stream Capability (N addr blocks)
        RP_IDE_SEL_STS      = 4'b1001,  // Selective IDE Stream Status (sel block+0x08)
        RP_IDE_WAIT         = 4'b1010,  // delay between sweeps
        RP_IDE_SECURE       = 4'b1011,  // a stream is Secure; no further DBI accesses
        RP_IDE_NONE         = 4'b1100   // capability reports no Link/Selective IDE; no further DBI accesses
    } rp_config_state_t;

    // State machine registers
    rp_config_state_t current_state, next_state;

    // IDE status polling (PCIe Base 6.2 7.9.26). Offsets are within the RP config space.
    localparam logic [31:0] RP_CFG_BASE     = RP_CTRL1 ? 32'hFC400000 : 32'hFC000000;
    localparam logic [3:0]  IDE_STATE_SECURE = 4'b0010;
    localparam logic [11:0] ide_base        = IDE_CAP_OFFSET;   // IDE capability offset (fixed per device)

    logic                           ide_link_sup, ide_sel_sup;
    logic [2:0]                     ide_num_tc;     // Link IDE streams - 1
    logic [7:0]                     ide_num_sel;    // Selective IDE streams - 1
    logic [2:0] ide_link_idx;
    logic [7:0] ide_sel_idx;
    logic [11:0]                    ide_sel_off;    // current Selective IDE stream block
    logic [3:0]                     ide_sel_naddr;  // its number of address association blocks
    logic [$clog2(IDE_POLL_INTERVAL+1)-1:0] ide_wait_cnt;
    logic [31:0] ide_last_sts;  // last stream status read
    logic [11:0]                    ide_rd_off;     // offset for the current IDE read
    logic                           ide_sts_secure;

    assign ide_sts_secure = (cfg_cpl_data[3:0] == IDE_STATE_SECURE);
    assign ide_secure      = IDE_EN && (current_state == RP_IDE_SECURE);
    assign ide_cap_missing = IDE_EN && (current_state == RP_IDE_NONE);

    always_comb begin
        case (current_state)
            RP_IDE_CAP:      ide_rd_off = ide_base + 12'h004;
            RP_IDE_LINK_STS: ide_rd_off = ide_base + 12'h00C + {6'd0, ide_link_idx, 3'b000} + 12'h004;
            RP_IDE_SEL_CAP:  ide_rd_off = ide_sel_off;
            RP_IDE_SEL_STS:  ide_rd_off = ide_sel_off + 12'h008;
            default:         ide_rd_off = '0;
        endcase
    end

    // State machine logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || link_down) begin
            current_state <= RP_ROM_CONFIG;
        end else begin
            current_state <= next_state;
        end
    end

    always_ff @(posedge clk  or negedge rst_n) begin
        if (!rst_n || link_down) begin
            cfg_cpl_valid <= '0;
        end else begin
            cfg_cpl_valid <= cfg_cpl_valid_wire;
        end
    end

    // Next state logic
    always_comb begin
        next_state = current_state; // Default: stay in current state
        rp_cfg_wire = '0; // Default to zero
        
        case (current_state)
            RP_ROM_CONFIG: begin
                rp_cfg_wire = rp_cfg; 
                if (rp_rom_config_done && cfg_cpl_valid_wire)
                    next_state = RP_DEV_CAP_READ;
            end
            
            RP_DEV_CAP_READ: begin
                rp_cfg_wire.cfg_type =  1'b1; //  read RP_DEV_CAP
                if (RP_CTRL1)
                    rp_cfg_wire.addr = 'hFC400074;
                else if (RP_CTRL0)
                    rp_cfg_wire.addr = 'hFC000074;
                rp_cfg_wire.data = '0; 
                rp_cfg_wire.valid = 1'b1; 
                rp_cfg_wire.expected_data = '0; 

                if (cfg_cpl_valid_wire)
                    next_state = RP_DEV_CAP_WRITE;
            end
            
            RP_DEV_CAP_WRITE: begin
                rp_cfg_wire.cfg_type = 1'b0; //  write RP_DEV_CAP -> set tag enable and mps
                if (RP_CTRL1)
                    rp_cfg_wire.addr = 'hFC400074; // Address for RP_DEV_CAP
                else if (RP_CTRL0)
                    rp_cfg_wire.addr = 'hFC000074; // Address for RP_DEV_CAP
                rp_cfg_wire.data = EXTENDED_TAG_EN ? ((next_cfg_write_data & mps_cap_mask) | 32'h20) : (next_cfg_write_data & mps_cap_mask) & 32'hFFFFFFDF; // Data to write
                rp_cfg_wire.valid = 1'b1; // Valid signal for the configuration
                rp_cfg_wire.expected_data = '0; // Expected data for the configuration
                if (cfg_cpl_valid_wire)
                    next_state = RP_DEV_CTRL_READ;
            end
            
            RP_DEV_CTRL_READ: begin
                rp_cfg_wire.cfg_type = 1'b1;//  read RP_DEV_CTRL
                if (RP_CTRL1)
                    rp_cfg_wire.addr = 'hFC400078; // Address for RP_DEV_CTRL
                else if (RP_CTRL0)
                    rp_cfg_wire.addr = 'hFC000078; // Address for RP_DEV_CTRL
                rp_cfg_wire.data = '0; // Data to read
                rp_cfg_wire.valid = 1'b1; // Valid signal for the configuration
                rp_cfg_wire.expected_data = '0; // Expected data for the configuration
                if (cfg_cpl_valid_wire)
                    next_state = RP_DEV_CTRL_WRITE;
            end
            
            RP_DEV_CTRL_WRITE: begin
                rp_cfg_wire.cfg_type = 1'b0; //  write RP_DEV_CTRL -> set mps
                
                if (RP_CTRL1)
                    rp_cfg_wire.addr = 'hFC400078; // Address for RP_DEV_CTRL
                else if (RP_CTRL0)
                    rp_cfg_wire.addr = 'hFC000078; // Address for RP_DEV_CTRL
                rp_cfg_wire.data = EXTENDED_TAG_EN ? ((next_cfg_write_data & mps_ctrl_mask) | 32'h100) : (next_cfg_write_data & mps_ctrl_mask) & 32'hFFFFFEFF; // Data to write
                rp_cfg_wire.valid = 1'b1; // Valid signal for the configuration
                rp_cfg_wire.expected_data = '0; // Expected data for the configuration
                if (cfg_cpl_valid_wire) begin
                    next_state = IDE_EN ? RP_IDE_CAP : RP_ROM_CONFIG; // Stay in RP_ROM_CONFIG once complete
                end
            end

            RP_IDE_CAP, RP_IDE_LINK_STS, RP_IDE_SEL_CAP, RP_IDE_SEL_STS: begin
                rp_cfg_wire.cfg_type = 1'b1; // read
                rp_cfg_wire.addr = RP_CFG_BASE | {20'd0, ide_rd_off};
                rp_cfg_wire.valid = 1'b1;
                if (cfg_cpl_valid_wire) begin
                    case (current_state)
                        RP_IDE_CAP:
                            if (cfg_cpl_data[0])        next_state = RP_IDE_LINK_STS;
                            else if (cfg_cpl_data[1])   next_state = RP_IDE_SEL_CAP;
                            else                        next_state = RP_IDE_NONE;
                        RP_IDE_LINK_STS:
                            if (ide_sts_secure)                     next_state = RP_IDE_SECURE;
                            else if (ide_link_idx == ide_num_tc)    next_state = ide_sel_sup ? RP_IDE_SEL_CAP : RP_IDE_WAIT;
                        RP_IDE_SEL_CAP:
                            next_state = RP_IDE_SEL_STS;
                        RP_IDE_SEL_STS:
                            if (ide_sts_secure)                     next_state = RP_IDE_SECURE;
                            else if (ide_sel_idx == ide_num_sel)    next_state = RP_IDE_WAIT;
                            else                                    next_state = RP_IDE_SEL_CAP;
                        default: ;
                    endcase
                end
            end

            RP_IDE_WAIT: begin
                if (ide_wait_cnt == IDE_POLL_INTERVAL)
                    next_state = RP_IDE_CAP;    // re-read the capability and sweep again
            end

            RP_IDE_SECURE, RP_IDE_NONE: begin
                next_state = current_state;     // park; reset or link-down restarts
            end

            default: next_state = RP_ROM_CONFIG;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_cfg_write_data <= '0;
        end
        else if (link_down) begin
            next_cfg_write_data <= '0; // Reset on link down
        end
        else begin
            next_cfg_write_data <= cfg_cpl_data; // Update with current completion data
        end
    end

    // IDE walk/sweep bookkeeping, updated as each read completes
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || link_down) begin
            ide_link_sup  <= 1'b0;
            ide_sel_sup   <= 1'b0;
            ide_num_tc    <= '0;
            ide_num_sel   <= '0;
            ide_link_idx  <= '0;
            ide_sel_idx   <= '0;
            ide_sel_off   <= '0;
            ide_sel_naddr <= '0;
            ide_wait_cnt  <= '0;
            ide_last_sts  <= '0;
        end else if (IDE_EN) begin
            ide_wait_cnt <= (current_state == RP_IDE_WAIT) ? ide_wait_cnt + 1'b1 : '0;
            if (cfg_cpl_valid_wire) begin
                case (current_state)
                    RP_IDE_CAP: begin
                        ide_link_sup <= cfg_cpl_data[0];
                        ide_sel_sup  <= cfg_cpl_data[1];
                        ide_num_tc   <= cfg_cpl_data[15:13];
                        ide_num_sel  <= cfg_cpl_data[23:16];
                        ide_link_idx <= '0;
                        ide_sel_idx  <= '0;
                        // Selective blocks follow the Link blocks (8 bytes per TC) if present
                        ide_sel_off  <= ide_base + 12'h00C +
                                        (cfg_cpl_data[0] ? {5'd0, cfg_cpl_data[15:13] + 4'd1, 3'b000} : 12'h000);
                    end
                    RP_IDE_LINK_STS: begin
                        ide_last_sts <= cfg_cpl_data;
                        ide_link_idx <= ide_link_idx + 1'b1;
                    end
                    RP_IDE_SEL_CAP: begin
                        ide_sel_naddr <= cfg_cpl_data[3:0];
                    end
                    RP_IDE_SEL_STS: begin
                        ide_last_sts <= cfg_cpl_data;
                        ide_sel_idx  <= ide_sel_idx + 1'b1;
                        // next block: 5 registers + 3 per address association block
                        ide_sel_off  <= ide_sel_off + 12'd20 + (ide_sel_naddr * 12'd12);
                    end
                    default: ;
                endcase
            end
        end
    end

    assign mps_cap_mask = 32'hFFFFFFF8; // Mask for MPS configuration
    assign mps_ctrl_mask = 32'hFFFFFF1F; // Mask for MPS control

    // Configuration done signal
    assign overall_rp_config_done_wire = (current_state == RP_DEV_CTRL_WRITE) && cfg_cpl_valid_wire;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || link_down) begin
            overall_rp_config_done <= 1'b0;
        end else begin
            overall_rp_config_done <= overall_rp_config_done ? 1'b1 : overall_rp_config_done_wire;
        end
    end

    assign cfg_expected_data_wire = rp_cfg.valid ? rp_cfg.expected_data : cfg_expected_data_reg;
    assign cfg_type_wire = rp_cfg.valid ? rp_cfg.cfg_type : cfg_type_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || link_down) begin
            cfg_expected_data_reg <= '0;
            cfg_type_reg <= '0;
        end else begin
            cfg_expected_data_reg <= cfg_expected_data_wire;
            cfg_type_reg <= cfg_type_wire;
        end
    end

    assign cfg_rd_mismatch = (cfg_cpl_valid_wire && cfg_type_reg && current_state == RP_ROM_CONFIG) ? (cfg_expected_data_reg != cfg_cpl_data) : '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || link_down) begin
            cfg_mismatch_error_count <= '0;
        end else if (cfg_rd_mismatch) begin
            cfg_mismatch_error_count <= cfg_mismatch_error_count + 1;
        end
    end



    rp_config_pl_dbi #(
        .ADDR_WIDTH(32),         // 32-bit address width
        .DATA_WIDTH(32),         // 32-bit data width
        .AUSER(11),             // 11-bit AUSER width
        .RESP_USER(4)           // 4-bit response user width
    ) rp_config_pl_dbi_inst (
        .clk(clk),              // System clock
        .rst_n(rst_n),          // Active low reset
        .link_down(link_down),  // Link down signal

        // Config interface
        .rp_cfg(rp_cfg_wire),            // Config interface
        // AXI-Lite interface
        .pl_dbi_axil_if(pl_dbi_axil_if),            // AXI-Lite interface

        // Output completion
        .cfg_cpl_valid(cfg_cpl_valid_wire),                // Completion valid signal
        .cfg_cpl_data(cfg_cpl_data)                   // Completion data signal
    );

    // Configuration Status Handler
    rp_config_status #(
        .NUM_VFS(NUM_VFS),
        .NUM_PFS(NUM_PFS)
    ) rp_config_status_inst (
        .clk(clk),
        .rst_n(rst_n),
        .link_down(link_down),

        // PF Config Status inputs
        .pf_cfg_status_pvld(pf_cfg_status_pvld),
        .pf_cfg_status_info(pf_cfg_status_info),
        .pf_cfg_status_sos(pf_cfg_status_sos),
        .pf_cfg_status_func_num(pf_cfg_status_func_num),

        // VF Config Status inputs
        .vf_cfg_status_pvld(vf_cfg_status_pvld),
        .vf_cfg_status_info(vf_cfg_status_info),
        .vf_cfg_status_sos(vf_cfg_status_sos),
        .vf_cfg_status_func_num(vf_cfg_status_func_num),

        // PF Status Outputs
        .cfg_bus_master_en(cfg_bus_master_en),
        .cfg_mem_space_en(cfg_mem_space_en),
        .cfg_msi_en(cfg_msi_en),
        .cfg_msix_en(cfg_msix_en),
        .cfg_msix_func_mask(cfg_msix_func_mask),
        .cfg_pf_pasid_en(cfg_pf_pasid_en),
        .cfg_atomic_req_en(cfg_atomic_req_en),
        .cfg_max_rd_req_size(cfg_max_rd_req_size),
        .cfg_max_payload_size(cfg_max_payload_size),
        .cfg_ext_tag_en(cfg_ext_tag_en),
        .cfg_rcb(cfg_rcb),
        .cfg_flr_pf_active(cfg_flr_pf_active),
        .cfg_10b_tag_req_en(cfg_10b_tag_req_en),
        .cfg_vf_en(cfg_vf_en),
        .cfg_int_disable(cfg_int_disable),
        .pm_status(pm_status),
        .cfg_io_space_en(cfg_io_space_en),
        .cfg_pf_pasid_execute_perm_en(cfg_pf_pasid_execute_perm_en),
        .cfg_pf_pasid_priv_mode_en(cfg_pf_pasid_priv_mode_en),
        .cfg_ats_cache_en(cfg_ats_cache_en),
        .cfg_prs_enable(cfg_prs_enable),
        .cfg_tph_req_en(cfg_tph_req_en),
        .radm_pm_turnoff(radm_pm_turnoff),
        .cfg_pcie_cap_flit_mode_stat(cfg_pcie_cap_flit_mode_stat),

        // VF Status Outputs
        .cfg_vf_bme(cfg_vf_bme),
        .cfg_vf_msi_en(cfg_vf_msi_en),
        .cfg_vf_msix_en(cfg_vf_msix_en),
        .cfg_vf_msix_func_mask(cfg_vf_msix_func_mask),
        .cfg_flr_vf_active(cfg_flr_vf_active)
    );


endmodule