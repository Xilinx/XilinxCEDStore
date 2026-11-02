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

class rp_cfg_txn extends uvm_sequence_item;

    bit                   is_write; // 1 = write, 0 = read
    bit [pcie_rp_pkg::PLDBI_ADDR_WIDTH-1:0] addr;
    bit [pcie_rp_pkg::PLDBI_DATA_WIDTH-1:0] data;
    bit [pcie_rp_pkg::PLDBI_RESP_USER-1:0]  resp;

    `uvm_object_utils_begin(rp_cfg_txn)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(resp, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "rp_cfg_txn");
        super.new(name);
    endfunction

    function string sprint();
        return $sformatf("is_write=%0b, addr=0x%0h, data=0x%0h, resp=0x%0h", 
                        is_write, addr, data, resp);
    endfunction
endclass