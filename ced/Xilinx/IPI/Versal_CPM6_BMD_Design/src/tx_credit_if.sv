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

interface tx_credit_if;
// Core -> PL (Input)

    // Return credit valid
    logic               cr_valid;

    // Credit value encoding
    //      - 3'b000: 0  credits
    //      - 3'b001: 1  credits
    //      - 3'b010: 2  credits
    //      - 3'b011: 4  credits
    //      - 3'b100: 8  credits
    //      - 3'b101: 16 credits
    //      - 3'b110: 32 credits
    //      - 3'b111: 64 credits
    logic [2:0]         cr;

// PL -> Core (Output)

    // Credit interface is active.
    // 1'b0 after reset
    // 1'b1 indicates interface is active
    // Once 1'b1, signal ignored until next reset
    logic               cr_active;

    modport slave (
        input  cr_valid,
        input  cr,
        output cr_active
    );

    modport master (
        output cr_valid,
        output cr,
        input  cr_active
    );
endinterface
