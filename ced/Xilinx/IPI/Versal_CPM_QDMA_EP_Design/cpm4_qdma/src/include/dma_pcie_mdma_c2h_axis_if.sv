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

`ifndef IF_PCIE_MDMA_C2H_AXIS_SV
`define IF_PCIE_MDMA_C2H_AXIS_SV

`include "mdma_defines.svh"

interface dma_pcie_mdma_c2h_axis_if#()();
mdma_c2h_axis_data_t    data;  
mdma_c2h_axis_ctrl_t    ctrl;
logic                   tlast;
logic [5:0]             mty; 
logic                   tvalid;
logic                   tready;

modport m (
output    data,    
output    ctrl,
output    tlast,   
output    mty, 
output    tvalid,  
input     tready  
);

modport s (
input     data,    
input     ctrl,
input     tlast,   
input     mty, 
input     tvalid,  
output    tready  
);
endinterface : dma_pcie_mdma_c2h_axis_if
`endif
