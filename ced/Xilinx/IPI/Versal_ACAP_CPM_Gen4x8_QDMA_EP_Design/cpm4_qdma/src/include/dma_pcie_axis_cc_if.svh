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

`ifndef iF_AXIS_CC_PCIE_DMA_PORT_VS
`define iF_AXIS_CC_PCIE_DMA_PORT_VS
`timescale 1 ps / 1 ps
interface dma_pcie_axis_cc_if#(DATA_WIDTH = 512, USER_WIDTH = 81)();

  wire [DATA_WIDTH-1:0]     tdata;
  wire [USER_WIDTH-1:0]     tuser;
  wire                      tlast;
  wire [DATA_WIDTH/32-1:0]  tkeep;
  wire                 tvalid;
  wire                 tready;

  modport s (
    
    input              tdata
   ,input              tuser
   ,input              tlast
   ,input              tkeep
   ,input              tvalid
   ,output             tready

  );

  modport m (

    output             tdata
   ,output             tuser
   ,output             tlast
   ,output             tkeep
   ,output             tvalid
   ,input              tready

  );
  
endinterface : dma_pcie_axis_cc_if
`endif // iF_AXIS_CC_PCIE_PORT_VS
