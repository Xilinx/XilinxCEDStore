// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////

`ifndef IF_PCIE_DMA_C2H_CRDT_SV
`define IF_PCIE_DMA_C2H_CRDT_SV
interface dma_pcie_c2h_crdt_if #();
    logic   [511:0]             tdata;
    logic   [512/8-1:0]         tparity;
    logic                       tlast;
    logic   [512/8-1:0]         tkeep;
    logic   [127:0]             tusr;
    logic                       tvalid;
    logic   [1:0]               tch;

    logic                       crdt;
    logic   [1:0]               crdt_ch;

    modport m (
        output                      tdata,
        output                      tparity,
        output                      tlast,
        output                      tkeep,
        output                      tusr,
        output                      tvalid,
        output                      tch,

        input                       crdt,
        input                       crdt_ch
    );

    modport s (
        input                       tdata,
        input                       tparity,
        input                       tlast,
        input                       tkeep,
        input                       tusr,
        input                       tvalid,
        input                       tch,

        output                      crdt,
        output                      crdt_ch
    );

endinterface : dma_pcie_c2h_crdt_if
`endif
