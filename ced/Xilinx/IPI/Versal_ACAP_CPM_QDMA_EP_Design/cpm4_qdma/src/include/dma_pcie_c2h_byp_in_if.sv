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

`ifndef DMA_PCIE_C2H_BYP_IN_IF_SV
`define DMA_PCIE_C2H_BYP_IN_IF_SV
    interface dma_pcie_c2h_byp_in_if;
        logic [63 :0]                   dsc;
        logic [`QID_WIDTH-1:0]          qid;
        logic [21:0]                    len;
        logic                           last;
        logic  [1:0]                    chn;
        logic                           vld;
        logic  [1:0]                    crdt_chn;
        logic                           crdt;
        modport m (
            output          dsc,
            output          qid,
            output          len,
            output          last,
            output          chn,
            output          vld,
            input           crdt_chn,
            input           crdt
        );
        modport s (
            input           dsc,
            input           qid,
            input           len,
            input           last,
            input           chn,
            input           vld,
            output          crdt_chn,
            output          crdt
        );
    endinterface
`endif
