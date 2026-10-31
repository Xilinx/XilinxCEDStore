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

interface pl_dbi_if(
    input logic clk
); 

    // DBI Interface Signals
    logic [31:0] dbi_araddr;
    logic dbi_arvalid;
    logic [3:0] dbi_aruser;
    logic [2:0] dbi_arprot;
    logic dbi_arready;

    logic [31:0] dbi_rdata;
    logic [1:0] dbi_rresp;
    logic dbi_rvalid;
    logic dbi_rready;

    logic [31:0] dbi_awaddr;
    logic dbi_awvalid;
    logic [3:0] dbi_awuser;
    logic [2:0] dbi_awprot;
    logic dbi_awready;

    logic [31:0] dbi_wdata;
    logic [3:0] dbi_wstrb;
    logic dbi_wvalid;
    logic dbi_wready;

    logic [1:0] dbi_bresp;
    logic dbi_bvalid;
    logic dbi_bready;

    clocking dbi_cb @(posedge clk);
        input dbi_araddr;
        input dbi_arvalid;
        input dbi_aruser;
        input dbi_arprot;
        input dbi_arready;

        input dbi_rdata;
        input dbi_rresp;
        input dbi_rvalid;
        input dbi_rready;

        input dbi_awaddr;
        input dbi_awvalid;
        input dbi_awuser;
        input dbi_awprot;
        input dbi_awready;

        input dbi_wdata;
        input dbi_wstrb;
        input dbi_wvalid;
        input dbi_wready;

        input dbi_bresp;
        input dbi_bvalid;
        input dbi_bready;

    endclocking


    // Monitor modport - observe only, all directions 'input'. See dbi_cb above.
    modport monitor_mp(
        input clk,
        clocking dbi_cb,
        input dbi_araddr,
        input dbi_arvalid,
        input dbi_aruser,
        input dbi_arprot,
        input dbi_arready,

        input dbi_rdata,
        input dbi_rresp,
        input dbi_rvalid,
        input dbi_rready,

        input dbi_awaddr,
        input dbi_awvalid,
        input dbi_awuser,
        input dbi_awprot,
        input dbi_awready,

        input dbi_wdata,
        input dbi_wstrb,
        input dbi_wvalid,
        input dbi_wready,

        input dbi_bresp,
        input dbi_bvalid,
        input dbi_bready
    );


endinterface




