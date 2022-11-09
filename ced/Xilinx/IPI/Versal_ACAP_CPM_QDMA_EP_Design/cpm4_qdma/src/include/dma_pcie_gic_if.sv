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
`ifndef IF_PCIE_DMA_GIC_SV
`define IF_PCIE_DMA_GIC_SV
interface dma_pcie_gic_if();
    logic [2:0] interrupt;
modport m (
    output interrupt
);
modport s (
    input interrupt
);

endinterface : dma_pcie_gic_if
`endif
