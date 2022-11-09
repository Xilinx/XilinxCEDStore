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

`ifndef IF_PCIE_DMA_C2H_AXIS_SV
`define IF_PCIE_DMA_C2H_AXIS_SV
`timescale 1 ps / 1 ps
interface dma_pcie_c2h_axis_if#()();
logic  [511:0]       tdata;
logic  [512/8-1:0]   tparity;
logic                tlast;
logic                tvalid;
logic  [512/8-1:0]   tkeep;
logic                tready;
logic  [63:0]        tusr;

modport m (
output     tdata,
output     tparity,
output     tlast,
output     tvalid,
output     tkeep,
output     tusr,
input      tready
);

modport s (
input       tdata,
input       tparity,
input       tlast,
input       tvalid,
input       tkeep,
input       tusr,
output      tready
);
endinterface : dma_pcie_c2h_axis_if
`endif
