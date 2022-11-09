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

`ifndef IF_PCIE_DMA_DSC_IN_SV
`define IF_PCIE_DMA_DSC_IN_SV
`include "dma_defines.svh"

interface dma_pcie_dsc_in_if();
    dma_dsc_in_crd_t      crd;
    dma_dsc_block_t       dsc;

modport snk (
input  dsc,
output  crd
);

modport src (
input dsc,
output crd
);

endinterface : dma_pcie_dsc_in_if
`endif
