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

interface dut_err_cnt_if(
    input logic clk
);

    pcie_intf_pkg::error_counters_t error_counts;

    // Clocking block specifically for the monitor
    // This ensures proper signal sampling and prevents race conditions
    clocking monitor_cb @(posedge clk);
        input error_counts;  // Sample the entire struct as one unit
    endclocking

    // Modport for the monitor - restricts access to just what's needed
    modport monitor_mp (
        clocking monitor_cb,
        input error_counts,
        input clk
    );
endinterface