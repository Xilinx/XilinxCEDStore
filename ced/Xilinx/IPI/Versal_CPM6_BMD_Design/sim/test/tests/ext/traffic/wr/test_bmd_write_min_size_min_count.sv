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
// test_bmd_write_min_size_min_count.sv - Write Traffic BMD Tests
//==============================================================================
// Description:
//   BMD test that creates 1 write of 1 DW length
//==============================================================================

class test_bmd_write_min_size_min_count extends test_bmd;
    `uvm_component_utils(test_bmd_write_min_size_min_count)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_write_min_size_min_count", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra();

        csr_cfg.wr_start = 1'b1;
        csr_cfg.rd_start = 1'b0;

        csr_cfg.wr_size = 9'h001;
        csr_cfg.wr_count = 16'h0001;

        csr_cfg.wr_upper_be = 4'b0000;

    endtask

endclass : test_bmd_write_min_size_min_count
