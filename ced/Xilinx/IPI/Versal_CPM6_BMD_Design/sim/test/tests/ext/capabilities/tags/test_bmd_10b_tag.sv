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
// test_bmd_10b_tag.sv - Capability Tag BMD Tests
//==============================================================================
// Description:
//   BMD test that creates random read and write traffic that use 10b tags
//==============================================================================

class test_bmd_10b_tag extends test_bmd;
    `uvm_component_utils(test_bmd_10b_tag)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_10b_tag", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        csr_cfg.wr_start            = 1'b1;
        csr_cfg.rd_start            = 1'b1;

        cap_cfg.cfg_10b_tag_req_en  = 1'b1;
        cap_cfg.cfg_ext_tag_en      = 1'b1;

    endtask

endclass : test_bmd_10b_tag
