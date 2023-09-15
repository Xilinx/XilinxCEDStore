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

`ifndef DMA_PCIE_MI_PASID_RAM_IF_SV
`define DMA_PCIE_MI_PASID_RAM_IF_SV

//PASID RAM interfaces to RAM in PCIE hard block. Each RAM is 64Bx512
interface dma_pcie_mi_pasid_ram_if();
                logic   [11:0]      addr;
                logic   [3:0]       wen;
                logic               ren;
                logic   [35:0]      wdata;
               
                logic   [35:0]      rdata;
                logic               cor;
                logic               uncor;

modport m (
                output        addr,
                output        wen,
                output        ren,
                output        wdata,
	        
                input         rdata,
	        input         cor,
	        input         uncor        
);

modport s (
                input         addr,
                input         wen,
                input         ren,
                input         wdata,
                
                output        rdata,
	        output        cor,
                output        uncor
);
endinterface 

`endif
