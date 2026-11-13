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

class cr_txn extends uvm_sequence_item;

    int credit_used;
    int credit_received;
    int credit_available;

    `uvm_object_utils_begin(cr_txn)
        `uvm_field_int(credit_used, UVM_ALL_ON)
        `uvm_field_int(credit_received, UVM_ALL_ON)
        `uvm_field_int(credit_available, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "cr_txn");
        super.new(name);
    endfunction

    function string sprint();
        return $sformatf("credit_used=%0d, credit_received=%0d, credit_available=%0d", 
                        credit_used, credit_received, credit_available);
    endfunction

endclass