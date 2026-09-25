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
// bmd_out_of_range_read_seq.sv - BMD Out-of-Range CSR Read Sequence
//==============================================================================
// Reads an invalid CSR address to generate Unsupported Request
//==============================================================================

class bmd_out_of_range_read_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_out_of_range_read_seq_c)

    //--------------------------------------------------------------------------
    // Configuration
    //--------------------------------------------------------------------------
    rand bit [6:0] out_of_range_addr;

    constraint out_of_range_c {
        // Max CSR address from bmd mem pkg
        out_of_range_addr > MAX_CSR;
    }

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_out_of_range_read_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        bit [31:0] rd_data;

        // Perform out-of-range CSR read
        issue_csr_read(out_of_range_addr, rd_data);

        `uvm_info(get_name(), $sformatf("Performed out-of-range CSR read: addr=0x%h", out_of_range_addr), UVM_MEDIUM)

    endtask

endclass
