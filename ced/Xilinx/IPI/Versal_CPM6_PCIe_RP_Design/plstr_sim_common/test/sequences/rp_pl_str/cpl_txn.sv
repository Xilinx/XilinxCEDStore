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

class cpl_txn extends uvm_sequence_item;
    // Completion Transaction Fields
    rand bit [15:0]       tag;
    rand bit [7:0]        typ;          // Combination of fmt and type
    rand bit [11:0]       length;       // Length in DW
    rand bit [15:0]       cpl_id;       // Completer ID
    rand bit [2:0]        status;       // Completion Status
    rand bit [31:0]       data;      // Completion Data

    `uvm_object_utils_begin(cpl_txn)
        `uvm_field_int(tag, UVM_ALL_ON)
        `uvm_field_int(typ, UVM_ALL_ON)
        `uvm_field_int(length, UVM_ALL_ON)
        `uvm_field_int(cpl_id, UVM_ALL_ON)
        `uvm_field_int(status, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor
    function new(string name = "cpl_txn");
        super.new(name);
    endfunction

    // Print method for debugging
    function string sprint();
        return $sformatf("CPL_TXN: Tag=0x%0h, Type=0x%0h, Length=%0d, Cpl_ID=0x%0h, Status=0x%0h",
                         tag, typ, length, cpl_id, status);
    endfunction
endclass