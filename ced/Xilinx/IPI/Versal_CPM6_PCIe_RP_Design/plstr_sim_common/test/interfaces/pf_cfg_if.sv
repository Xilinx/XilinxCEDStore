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

import cfg_status_pkg::*;

interface pf_cfg_if(
    input logic clk
);
    logic               pf_cfg_status_pvld;
    pf_cfg_t            pf_cfg_status_info;
    logic               pf_cfg_status_sos;
    logic [2:0]         pf_cfg_status_func_num;

    // Clocking block specifically for the monitor
    // This ensures proper signal sampling and prevents race conditions
    clocking monitor_cb @(posedge clk);
        input pf_cfg_status_pvld;
        input pf_cfg_status_info;
        input pf_cfg_status_sos;
        input pf_cfg_status_func_num;
    endclocking

    // Modport for the monitor - restricts access to just what's needed
    modport monitor_mp (
        clocking monitor_cb,
        input pf_cfg_status_pvld,
        input pf_cfg_status_info,
        input pf_cfg_status_sos,
        input pf_cfg_status_func_num,
        input clk
    );
endinterface