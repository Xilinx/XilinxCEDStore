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

`ifndef MAILBOX_AXI4LITE_IF_SV
`define MAILBOX_AXI4LITE_IF_SV

`timescale 1ns/1ps
interface mailbox_axi4lite_if
#(
 parameter integer AXIL_ADDR_W = 32,
 parameter integer AXIL_DATA_W = 32,
 parameter integer AXIL_USER_W = 29,
 parameter integer AXIL_STRB_W = AXIL_DATA_W/8
) (
);

 //AXI-Lite WRITE-interface
 logic                         awvalid;
 logic       [AXIL_ADDR_W-1:0] awaddr;
 logic                   [2:0] awprot;
 logic       [AXIL_USER_W-1:0] awuser;
 logic                         awready;
 logic                         wvalid;
 logic       [AXIL_USER_W-1:0] wuser;
 logic       [AXIL_DATA_W-1:0] wdata;
 logic       [AXIL_STRB_W-1:0] wstrb;
 logic                         wready;
 logic                         bvalid;
 logic      [AXIL_USER_W-1:0]  buser;
 logic                  [1:0]  bresp;
 logic                         bready;
 //AXI-Lite READ-interface
 logic                         arvalid;
 logic       [AXIL_USER_W-1:0] aruser;
 logic       [AXIL_ADDR_W-1:0] araddr;
 logic                   [2:0] arprot;
 logic                         arready;
 logic                         rvalid;
 logic      [AXIL_USER_W-1:0]  ruser;
 logic      [AXIL_DATA_W-1:0]  rdata;
 logic                  [1:0]  rresp;
 logic                         rready;

modport s (
 //AXI-Lite WRITE-interface
 input       awvalid,
 input       awuser,
 input       awaddr,
 input       awprot,
 output      awready,
 input       wvalid,
 input       wuser,
 input       wdata,
 input       wstrb,
 output      wready,
 output      bvalid,
 output      buser,
 output      bresp,
 input       bready,
 //AXI-Lite READ-interface
 input       arvalid,
 input       aruser,
 input       araddr,
 input       arprot,
 output      arready,
 output      rvalid,
 output      ruser,
 output      rdata,
 output      rresp,
 input       rready
);

modport m (
 //AXI-Lite WRITE-interface
 output      awvalid,
 output      awuser,
 output      awaddr,
 output      awprot,
 input       awready,
 output      wvalid,
 output      wuser,
 output      wdata,
 output      wstrb,
 input       wready,
 input       bvalid,
 input       buser,
 input       bresp,
 output      bready,
 //AXI-Lite READ-interface
 output      arvalid,
 output      aruser,
 output      araddr,
 output      arprot,
 input       arready,
 input       rvalid,
 input       ruser,
 input       rdata,
 input       rresp,
 output      rready
);

endinterface
`endif
