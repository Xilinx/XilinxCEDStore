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

`ifndef IF_PCIE_DMA_CRDT_SV
`define IF_PCIE_DMA_CRDT_SV
interface dma_pcie_crdt_if #(
    parameter DATA_BITS=512,
    parameter CH_BITS=2
);
logic   [DATA_BITS-1:0]     tl_tdata;
logic                       tl_tvld;
logic   [CH_BITS-1:0]       tl_tch;

logic                       tl_crdt;
logic   [CH_BITS-1:0]       tl_crdt_ch;

    modport m (
        output  tl_tdata,
        output  tl_tvld,
        output  tl_tch,

        input   tl_cvld,
        input   tl_cch
    );

    modport s (
        input   tl_tdata,
        input   tl_tvld,
        input   tl_tch,

        output  tl_cvld,
        output  tl_cch
    );

endinterface : dma_pcie_crdt_if
`endif
