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

interface plstr_credit_if (
    input logic clk
);
    // The monitor will sample this struct on clock edges
    // Credit value encoding
    //      - 3'b000: 0  credits
    //      - 3'b001: 1  credits
    //      - 3'b010: 2  credits
    //      - 3'b011: 4  credits
    //      - 3'b100: 8  credits
    //      - 3'b101: 16 credits
    //      - 3'b110: 32 credits
    //      - 3'b111: 64 credits
    logic [2:0]   cr;
    logic         cr_valid;
    logic         cr_active;

    // Clocking block specifically for the monitor
    // This ensures proper signal sampling and prevents race conditions
    clocking monitor_cb @(posedge clk);
        input cr;
        input cr_valid;
        input cr_active;
    endclocking

    // Modport for the monitor - restricts access to just what's needed
    modport monitor_mp (
        clocking monitor_cb
    );
endinterface
