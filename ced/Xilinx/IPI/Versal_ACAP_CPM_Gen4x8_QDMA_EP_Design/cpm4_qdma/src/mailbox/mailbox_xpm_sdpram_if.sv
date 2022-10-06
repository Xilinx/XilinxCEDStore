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

`ifndef MAILBOX_XPM_SDPRAM_IF_SV
`define MAILBOX_XPM_SDPRAM_IF_SV

`timescale 1ns/1ps
interface mailbox_xpm_sdpram_if
#(
  parameter MEM_W=128,
  parameter ADR_W=9,  
  parameter WBE_W=1,
  parameter PAR_W=MEM_W/8  
) (
);

  logic  [WBE_W-1:0]     we;
  logic  [ADR_W-1:0]     wad;
  logic  [MEM_W-1:0]     wdt;
  logic  [PAR_W-1:0]     wpar;
  logic                  re;
  logic  [ADR_W-1:0]     rad;
  logic  [MEM_W-1:0]     rdt;
  logic  [PAR_W-1:0]     rpar;
  logic                  sbe;
  logic                  dbe;

modport m (
                output        wad,
                output        we,
                output        wpar,
                output        wdt,
                output        re,
                output        rad,

                input         rpar,
                input         rdt,
                input         sbe,
                input         dbe
);

modport s (
                input         wad,
                input         we,
                input         wpar,
                input         wdt,
                input         re,
                input         rad,

                output        rpar,
                output        rdt,
                output        sbe,
                output        dbe
);
endinterface
`endif
