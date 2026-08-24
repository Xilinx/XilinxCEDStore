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

// This provides a way to send the captured data through UVM analysis ports
class rx_str_transaction extends uvm_sequence_item;

// 00, posted, 01, non-posted, 10, completion, 11, non-posted w/ data
logic [pcie_str_pkg::START_TYPE_WIDTH-1:0]  ttype;
logic [pcie_str_pkg::RX_SLOT_WIDTH-1:0]     header;
logic [pcie_str_pkg::DATA_SLOT_WIDTH-1:0]   data[];

`uvm_object_utils_begin(rx_str_transaction)
    `uvm_field_int(ttype, UVM_ALL_ON)
    `uvm_field_int(header, UVM_ALL_ON)
    `uvm_field_array_int(data, UVM_ALL_ON)
`uvm_object_utils_end

function new(string name = "rx_str_transaction");
    super.new(name);
endfunction

endclass
