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
    parameter EXTENDED_TAG_EN = 1      // Extended tag enable
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
    output logic                          overall_rp_config_done
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
    typedef enum logic [2:0] {
        RP_ROM_CONFIG       = 3'b000,
        RP_DEV_CAP_READ     = 3'b001,
        RP_DEV_CAP_WRITE    = 3'b010,
        RP_DEV_CTRL_READ    = 3'b011,
        RP_DEV_CTRL_WRITE   = 3'b100
    } rp_config_state_t;

    // State machine registers
    rp_config_state_t current_state, next_state;

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
                    next_state = RP_ROM_CONFIG; // Stay in this state once complete
                end
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