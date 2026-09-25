// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
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

//
// Project    : Versal PCI Express Integrated Block
// File       : BMD_AXIST_TO_CTRL.sv
// Version    : 1.0 
//-----------------------------------------------------------------------------

`include "pcie_app_versal_bmd.vh"
`timescale 1ps / 1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_TO_CTRL #(
   parameter         TCQ                              = 1
)(
   input                            clk,
   input                            rst_n,

   input                            req_compl,
   input                            cfg_power_state_change_interrupt,
   output logic                     cfg_power_state_change_ack
);

   logic                            trn_pending;

  //  Check if completion is pending
   `BMDREG(clk, rst_n, trn_pending, (~trn_pending & req_compl), 1'b0)

  //  Turn-off OK if requested and no transaction is pending
   `BMDREG(clk, rst_n, cfg_power_state_change_ack, (cfg_power_state_change_interrupt & ~trn_pending), 1'b0)
endmodule // BMD_AXIST_TO_CTRL

