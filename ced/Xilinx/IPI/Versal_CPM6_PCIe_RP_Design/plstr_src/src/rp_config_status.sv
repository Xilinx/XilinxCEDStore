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

module rp_config_status #(
    parameter NUM_VFS = 256,
    parameter NUM_PFS = 8
)
(
    input  logic clk,
    input  logic rst_n,
    input  logic link_down, 

    //PF Config Status
    input  logic                            pf_cfg_status_pvld,
    input  logic [15:0]                     pf_cfg_status_info,
    input  logic                            pf_cfg_status_sos,
    input  logic [2:0]                      pf_cfg_status_func_num,

    //VF Config Status
    input  logic                            vf_cfg_status_pvld,
    input  logic [15:0]                     vf_cfg_status_info,
    input  logic                            vf_cfg_status_sos,
    input  logic [7:0]                      vf_cfg_status_func_num,

    output logic [NUM_PFS-1:0]              cfg_bus_master_en,
    output logic [NUM_PFS-1:0]              cfg_mem_space_en,
    output logic [NUM_PFS-1:0]              cfg_msi_en,
    output logic [NUM_PFS-1:0]              cfg_msix_en,
    output logic [NUM_PFS-1:0]              cfg_msix_func_mask,
    output logic [NUM_PFS-1:0]              cfg_pf_pasid_en,
    output logic [NUM_PFS-1:0]              cfg_atomic_req_en,
    output logic [NUM_PFS-1:0][2:0]         cfg_max_rd_req_size,
    output logic [NUM_PFS-1:0][2:0]         cfg_max_payload_size,
    output logic [NUM_PFS-1:0]              cfg_ext_tag_en,
    output logic [NUM_PFS-1:0]              cfg_rcb,
    output logic [NUM_PFS-1:0]              cfg_flr_pf_active,

    output logic [NUM_PFS-1:0]              cfg_10b_tag_req_en,
    output logic [NUM_PFS-1:0]              cfg_vf_en,
    output logic [NUM_PFS-1:0]              cfg_int_disable,
    output logic [NUM_PFS-1:0]              pm_status,
    output logic [NUM_PFS-1:0]              cfg_io_space_en,
    output logic [NUM_PFS-1:0]              cfg_pf_pasid_execute_perm_en,
    output logic [NUM_PFS-1:0]              cfg_pf_pasid_priv_mode_en,
    output logic [NUM_PFS-1:0]              cfg_ats_cache_en,
    output logic [NUM_PFS-1:0]              cfg_prs_enable,
    output logic [NUM_PFS-1:0][1:0]         cfg_tph_req_en,
    output logic [NUM_PFS-1:0]              radm_pm_turnoff,
    output logic [NUM_PFS-1:0]              cfg_pcie_cap_flit_mode_stat,

    output logic [NUM_VFS-1:0]              cfg_vf_bme,
    output logic [NUM_VFS-1:0]              cfg_vf_msi_en,
    output logic [NUM_VFS-1:0]              cfg_vf_msix_en,
    output logic [NUM_VFS-1:0]              cfg_vf_msix_func_mask,
    output logic [NUM_VFS-1:0]              cfg_flr_vf_active

);

    logic [NUM_PFS-1:0]         cfg_bus_master_en_wire;
    logic [NUM_PFS-1:0]         cfg_mem_space_en_wire;
    logic [NUM_PFS-1:0]         cfg_msi_en_wire;
    logic [NUM_PFS-1:0]         cfg_msix_en_wire;
    logic [NUM_PFS-1:0]         cfg_msix_func_mask_wire;
    logic [NUM_PFS-1:0]         cfg_pf_pasid_en_wire;
    logic [NUM_PFS-1:0]         cfg_atomic_req_en_wire;
    logic [NUM_PFS-1:0][2:0]    cfg_max_rd_req_size_wire;
    logic [NUM_PFS-1:0][2:0]    cfg_max_payload_size_wire;
    logic [NUM_PFS-1:0]         cfg_ext_tag_en_wire;
    logic [NUM_PFS-1:0]         cfg_rcb_wire;
    logic [NUM_PFS-1:0]         cfg_flr_pf_active_wire;

    logic [NUM_PFS-1:0]         cfg_10b_tag_req_en_wire;
    logic [NUM_PFS-1:0]         cfg_vf_en_wire;
    logic [NUM_PFS-1:0]         cfg_int_disable_wire;
    logic [NUM_PFS-1:0]         pm_status_wire;
    logic [NUM_PFS-1:0]         cfg_io_space_en_wire;
    logic [NUM_PFS-1:0]         cfg_pf_pasid_execute_perm_en_wire;
    logic [NUM_PFS-1:0]         cfg_pf_pasid_priv_mode_en_wire;
    logic [NUM_PFS-1:0]         cfg_ats_cache_en_wire;
    logic [NUM_PFS-1:0]         cfg_prs_enable_wire;
    logic [NUM_PFS-1:0][1:0]    cfg_tph_req_en_wire;
    logic [NUM_PFS-1:0]         radm_pm_turnoff_wire;
    logic [NUM_PFS-1:0]         cfg_pcie_cap_flit_mode_stat_wire;

    logic [NUM_VFS-1:0]         cfg_vf_bme_wire;
    logic [NUM_VFS-1:0]         cfg_vf_msi_en_wire;
    logic [NUM_VFS-1:0]         cfg_vf_msix_en_wire;
    logic [NUM_VFS-1:0]         cfg_vf_msix_func_mask_wire;
    logic [NUM_VFS-1:0]         cfg_flr_vf_active_wire;

    logic cycle, cycle_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || link_down) begin
            cycle_reg <= 1'b0;
        end else if (pf_cfg_status_pvld) begin
            cycle_reg <= cycle;
        end
    end

    assign cycle = pf_cfg_status_sos ? 1'b1 : ~cycle_reg; // Use SOS signal to determine cycle

    // PF Config Status Handling

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || link_down) begin
            cfg_bus_master_en  <= '0;
            cfg_mem_space_en  <= '0;
            cfg_msi_en  <= '0;
            cfg_msix_en  <= '0;
            cfg_msix_func_mask  <= '0;
            cfg_pf_pasid_en  <= '0;
            cfg_atomic_req_en  <= '0;
            cfg_max_rd_req_size  <= '0;
            cfg_max_payload_size  <= '0;
            cfg_ext_tag_en  <= '0;
            cfg_rcb  <= '0;
            cfg_flr_pf_active  <= '0;

            cfg_10b_tag_req_en  <= '0;
            cfg_vf_en  <= '0;
            cfg_int_disable  <= '0;
            pm_status  <= '0;
            cfg_io_space_en  <= '0;
            cfg_pf_pasid_execute_perm_en  <= '0;
            cfg_pf_pasid_priv_mode_en  <= '0;
            cfg_ats_cache_en  <= '0;
            cfg_prs_enable  <= '0;
            cfg_tph_req_en  <= '0;
            radm_pm_turnoff  <= '0;
            cfg_pcie_cap_flit_mode_stat  <= '0;
        end
        else if (pf_cfg_status_pvld) begin
            cfg_bus_master_en            <= cfg_bus_master_en_wire;
            cfg_mem_space_en             <= cfg_mem_space_en_wire;
            cfg_msi_en                   <= cfg_msi_en_wire;
            cfg_msix_en                  <= cfg_msix_en_wire;
            cfg_msix_func_mask           <= cfg_msix_func_mask_wire;
            cfg_pf_pasid_en              <= cfg_pf_pasid_en_wire;
            cfg_atomic_req_en            <= cfg_atomic_req_en_wire;
            cfg_max_rd_req_size          <= cfg_max_rd_req_size_wire;
            cfg_max_payload_size         <= cfg_max_payload_size_wire;
            cfg_ext_tag_en               <= cfg_ext_tag_en_wire;
            cfg_rcb                      <= cfg_rcb_wire;
            cfg_flr_pf_active            <= cfg_flr_pf_active_wire;

            cfg_10b_tag_req_en           <= cfg_10b_tag_req_en_wire;
            cfg_vf_en                    <= cfg_vf_en_wire;
            cfg_int_disable              <= cfg_int_disable_wire;
            pm_status                    <= pm_status_wire;
            cfg_io_space_en              <= cfg_io_space_en_wire;
            cfg_pf_pasid_execute_perm_en <= cfg_pf_pasid_execute_perm_en_wire;
            cfg_pf_pasid_priv_mode_en    <= cfg_pf_pasid_priv_mode_en_wire;
            cfg_ats_cache_en             <= cfg_ats_cache_en_wire;
            cfg_prs_enable               <= cfg_prs_enable_wire;
            cfg_tph_req_en               <= cfg_tph_req_en_wire;
            radm_pm_turnoff              <= radm_pm_turnoff_wire;
            cfg_pcie_cap_flit_mode_stat  <= cfg_pcie_cap_flit_mode_stat_wire;
        end
    end


    always_comb begin
        // Default assignments from registered values
        cfg_bus_master_en_wire            = cfg_bus_master_en;
        cfg_mem_space_en_wire             = cfg_mem_space_en;
        cfg_msi_en_wire                   = cfg_msi_en;
        cfg_msix_en_wire                  = cfg_msix_en;
        cfg_msix_func_mask_wire           = cfg_msix_func_mask;
        cfg_pf_pasid_en_wire              = cfg_pf_pasid_en;
        cfg_atomic_req_en_wire            = cfg_atomic_req_en;
        cfg_max_rd_req_size_wire          = cfg_max_rd_req_size;
        cfg_max_payload_size_wire         = cfg_max_payload_size;
        cfg_ext_tag_en_wire               = cfg_ext_tag_en;
        cfg_rcb_wire                      = cfg_rcb;
        cfg_flr_pf_active_wire            = cfg_flr_pf_active;
        
        cfg_10b_tag_req_en_wire           = cfg_10b_tag_req_en;
        cfg_vf_en_wire                    = cfg_vf_en;
        cfg_int_disable_wire              = cfg_int_disable;
        pm_status_wire                    = pm_status;
        cfg_io_space_en_wire              = cfg_io_space_en;
        cfg_pf_pasid_execute_perm_en_wire = cfg_pf_pasid_execute_perm_en;
        cfg_pf_pasid_priv_mode_en_wire    = cfg_pf_pasid_priv_mode_en;
        cfg_ats_cache_en_wire             = cfg_ats_cache_en;
        cfg_prs_enable_wire               = cfg_prs_enable;
        cfg_tph_req_en_wire               = cfg_tph_req_en;
        radm_pm_turnoff_wire              = radm_pm_turnoff;
        cfg_pcie_cap_flit_mode_stat_wire  = cfg_pcie_cap_flit_mode_stat;


        if (!cycle_reg && pf_cfg_status_pvld) begin 

            cfg_bus_master_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[0];
            cfg_mem_space_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[1];
            cfg_msi_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[2];
            cfg_msix_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[3];
            cfg_msix_func_mask_wire[pf_cfg_status_func_num] = pf_cfg_status_info[4];
            cfg_pf_pasid_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[5];
            cfg_atomic_req_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[6];
            cfg_max_rd_req_size_wire[pf_cfg_status_func_num] = pf_cfg_status_info[9:7];
            cfg_max_payload_size_wire[pf_cfg_status_func_num] = pf_cfg_status_info[12:10];
            cfg_ext_tag_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[13];
            cfg_rcb_wire[pf_cfg_status_func_num] = pf_cfg_status_info[14];
            cfg_flr_pf_active_wire[pf_cfg_status_func_num] = pf_cfg_status_info[15];

        end else if (cycle_reg && pf_cfg_status_pvld) begin

            cfg_10b_tag_req_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[0];
            cfg_vf_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[1];
            cfg_int_disable_wire[pf_cfg_status_func_num] = pf_cfg_status_info[2];
            pm_status_wire[pf_cfg_status_func_num] = pf_cfg_status_info[3];
            cfg_io_space_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[4];
            cfg_pf_pasid_execute_perm_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[5];
            cfg_pf_pasid_priv_mode_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[6];
            cfg_ats_cache_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[7];
            cfg_prs_enable_wire[pf_cfg_status_func_num] = pf_cfg_status_info[8];
            cfg_tph_req_en_wire[pf_cfg_status_func_num] = pf_cfg_status_info[10:9];
            radm_pm_turnoff_wire[pf_cfg_status_func_num] = pf_cfg_status_info[14];
            cfg_pcie_cap_flit_mode_stat_wire[pf_cfg_status_func_num] = pf_cfg_status_info[15];
        end
    end

    // VF Config Status Handling

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || link_down) begin
            cfg_vf_bme <= '0;
            cfg_vf_msi_en <= '0;
            cfg_vf_msix_en <= '0;
            cfg_vf_msix_func_mask <= '0;
            cfg_flr_vf_active <= '0;
        end else if (vf_cfg_status_pvld) begin
            cfg_vf_bme <= cfg_vf_bme_wire;
            cfg_vf_msi_en <= cfg_vf_msi_en_wire;
            cfg_vf_msix_en <= cfg_vf_msix_en_wire;
            cfg_vf_msix_func_mask <= cfg_vf_msix_func_mask_wire;
            cfg_flr_vf_active <= cfg_flr_vf_active_wire;
        end
    end
    always_comb begin
        // Default assignments from registered values
        cfg_vf_bme_wire = cfg_vf_bme;
        cfg_vf_msi_en_wire = cfg_vf_msi_en;
        cfg_vf_msix_en_wire = cfg_vf_msix_en;
        cfg_vf_msix_func_mask_wire = cfg_vf_msix_func_mask;
        cfg_flr_vf_active_wire = cfg_flr_vf_active;

        if (vf_cfg_status_pvld) begin

            cfg_vf_bme_wire[vf_cfg_status_func_num] = vf_cfg_status_info[0];
            cfg_vf_msi_en_wire[vf_cfg_status_func_num] = vf_cfg_status_info[1];
            cfg_vf_msix_en_wire[vf_cfg_status_func_num] = vf_cfg_status_info[2];
            cfg_vf_msix_func_mask_wire[vf_cfg_status_func_num] = vf_cfg_status_info[3];
            cfg_flr_vf_active_wire[vf_cfg_status_func_num] = vf_cfg_status_info[4];

        end
    end

endmodule