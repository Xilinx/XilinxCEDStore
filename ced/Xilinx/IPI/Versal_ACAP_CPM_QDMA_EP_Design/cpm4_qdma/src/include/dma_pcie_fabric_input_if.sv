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

`ifndef IF_PCIE_DMA_FABRIC_INPUT_SV
`define IF_PCIE_DMA_FABRIC_INPUT_SV
interface dma_pcie_fabric_input_if();
logic               usr_irq_clr;
logic               usr_irq_set;
logic   [4:0]       usr_irq_vec;
logic   [7:0]       usr_irq_fnc;
logic               flr_done_vld;
logic   [7:0]       flr_done_fnc;

modport s (
input       usr_irq_clr,
input       usr_irq_set,
input       usr_irq_vec,
input       usr_irq_fnc,
input       flr_done_vld,
input       flr_done_fnc
);

modport m (
output       usr_irq_clr,
output       usr_irq_set,
output       usr_irq_vec,
output       usr_irq_fnc,
output       flr_done_vld,
output       flr_done_fnc
);
endinterface : dma_pcie_fabric_input_if
`endif
