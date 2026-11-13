////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
////////////////////////////////////////////////////////////////////////

`ifndef IF_PL_DBI_AXIL_IF
`define IF_PL_DBI_AXIL_IF
interface pl_dbi_axil_if #(DATA_WIDTH = 32, ADDR_WIDTH = 32, AUSER = 11, RESP_USER = 4)();


  logic [ADDR_WIDTH-1:0]     awaddr;
  logic                      awready;
  logic                      awvalid;
  logic [AUSER-1:0]          awuser;
  logic [2:0]                awprot;  

  logic [ADDR_WIDTH-1:0]     araddr;
  logic                      arready;
  logic                      arvalid;
  logic [AUSER-1:0]          aruser; 
  logic [2:0]                arprot;  

  logic [DATA_WIDTH-1:0]     wdata;
  logic [DATA_WIDTH/8-1:0]   wuser;
  logic [DATA_WIDTH/8-1:0]   wstrb;
  logic                      wready;
  logic                      wvalid;

  logic [DATA_WIDTH-1:0]     rdata;
  logic [1:0]                rresp;
  logic [DATA_WIDTH/8-1:0]   ruser;
  logic                      rready;
  logic                      rvalid;

  logic [1:0]                bresp;
  logic [RESP_USER-1:0]      buser;
  logic                      bready;
  logic                      bvalid;


  modport slave (
     input  awaddr
    ,output awready
    ,input  awvalid
    ,input  awuser
    ,input  awprot
    ,input  araddr
    ,output arready
    ,input  arvalid
    ,input  aruser
    ,input  arprot
    ,input  wdata
    ,input  wuser
    ,input  wstrb
    ,output wready
    ,input  wvalid
    ,output rdata
    ,output rresp
    ,output ruser
    ,input  rready
    ,output rvalid
    ,output bresp
    ,output buser
    ,input  bready
    ,output bvalid
  );

  modport master (
     output awaddr
    ,input  awready
    ,output awvalid
    ,output awuser
    ,output awprot
    ,output araddr
    ,input  arready
    ,output arvalid
    ,output aruser
    ,output arprot
    ,output wdata
    ,output wuser
    ,output wstrb
    ,input  wready
    ,output wvalid
    ,input  rdata
    ,input  rresp
    ,input  ruser
    ,output rready
    ,input  rvalid
    ,input  bresp
    ,input  buser
    ,output bready
    ,input  bvalid
  );

endinterface : pl_dbi_axil_if 
`endif // IF_PL_DBI_AXIL_IF 
