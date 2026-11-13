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

//// RX interface -> need control signals and slots
//// Control signals: will show the start and end of a packet and type of packet
//// Slots: will hold the actual packet data -  check slots here? for tlp/dllp err and tlp poisoned
//// Based on the control signals, calculate the credits to be returned, available credits etc
//// count completions received

class rx_str_txn extends uvm_sequence_item;

    logic                                           txn_valid;
    logic                                           txn_start;
    logic                                           txn_end;
    logic [2:0]                                     txn_type; //P; NP; NPD; CPL; CPLD; MSG
    logic                                           txn_h_or_d; //1: header; 0: data
    pcie_intf_pkg::rx_single_slot_data              txn_data;
    logic [pcie_str_pkg::END_DPTR_WIDTH-1:0]        txn_end_dptr;
    logic [pcie_str_pkg::END_ERROR_WIDTH-1:0]       txn_end_error;

    `uvm_object_utils_begin(rx_str_txn)
        `uvm_field_int(txn_valid, UVM_ALL_ON)
        `uvm_field_int(txn_start, UVM_ALL_ON)
        `uvm_field_int(txn_end, UVM_ALL_ON)
        `uvm_field_int(txn_type, UVM_ALL_ON)
        `uvm_field_int(txn_h_or_d, UVM_ALL_ON)
        `uvm_field_int(txn_data, UVM_ALL_ON)
        `uvm_field_int(txn_end_dptr, UVM_ALL_ON)
        `uvm_field_int(txn_end_error, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "rx_str_txn");
        super.new(name);
    endfunction

    function string sprint();
        return $sformatf("valid=%0b, start=%0b, end=%0b, type=%0b, h_or_d=%0b, data=%0h, end_dptr=0x%0h, end_error=0x%0h", 
                         txn_valid, txn_start, txn_end, txn_type, txn_h_or_d, txn_data, txn_end_dptr, txn_end_error);
    endfunction

endclass