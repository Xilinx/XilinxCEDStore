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
// test_bmd_striped_byte_enables.sv - Byte Enable Traffic BMD Tests
//==============================================================================
// Description:
//   BMD test that creates randomized read / write traffic with striped byte
//   enables
//==============================================================================

class test_bmd_striped_byte_enables extends test_bmd;
    `uvm_component_utils(test_bmd_striped_byte_enables)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_striped_byte_enables", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra();

        csr_cfg.rd_start = 1'b1;
        csr_cfg.wr_start = 1'b1;

        csr_cfg.wr_size  = 1;
        csr_cfg.rd_size  = 1;

        csr_cfg.rd_upper_be = 4'h0;
        csr_cfg.wr_upper_be = 4'h0;

        std::randomize(csr_cfg.rd_lower_be) with {
            csr_cfg.rd_lower_be inside {4'b0001, 4'b0010, 4'b0100, 4'b1000};
        };
        std::randomize(csr_cfg.wr_lower_be) with {
            csr_cfg.wr_lower_be inside {4'b0001, 4'b0010, 4'b0100, 4'b1000};
        };

    endtask

endclass : test_bmd_striped_byte_enables
