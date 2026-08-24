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

//==============================================================================
// test_bmd_custom_perf.sv - Custom Performance Measurement Test
//==============================================================================
// Description:
//   BMD test with custom write/read parameters for performance measurement.
//   Write: 2,000 TLPs x 256 DW (1024 bytes) = ~2 MB
//   Read:  2,000 TLPs x 256 DW (1024 bytes) = ~2 MB
//   Both directions active simultaneously.
//==============================================================================

class test_bmd_custom_perf extends test_bmd;
    `uvm_component_utils(test_bmd_custom_perf)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_custom_perf", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Override randomized CSR values
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra();

        // Force 10-bit tags (512 tags) to prevent tag exhaustion with high TLP counts
        cap_cfg.cfg_10b_tag_req_en = 1'b1;
        cap_cfg.cfg_ext_tag_en     = 1'b1;

        // Enable both write and read DMA
        csr_cfg.wr_start = 1'b1;
        csr_cfg.rd_start = 1'b1;

        // Write: 2,000 TLPs x 256 DW (max size)
        csr_cfg.wr_size  = 9'h100;       // 256 DW = 1024 bytes per TLP
        csr_cfg.wr_count = 16'd2000;

        // Read: 2,000 TLPs x 256 DW (max size)
        csr_cfg.rd_size  = 9'h100;       // 256 DW = 1024 bytes per TLP
        csr_cfg.rd_count = 16'd2000;

        // Prevent 4KB boundary crossing
        csr_cfg.wr_addr[9:0] = '0;
        csr_cfg.rd_addr[10:0] = '0;

        // Ensure byte enables are active
        if (csr_cfg.wr_upper_be == 4'b0000) csr_cfg.wr_upper_be = 4'b1111;
        if (csr_cfg.wr_lower_be == 4'b0000) csr_cfg.wr_lower_be = 4'b1111;
        if (csr_cfg.rd_upper_be == 4'b0000) csr_cfg.rd_upper_be = 4'b1111;
        if (csr_cfg.rd_lower_be == 4'b0000) csr_cfg.rd_lower_be = 4'b1111;

    endtask

endclass : test_bmd_custom_perf
