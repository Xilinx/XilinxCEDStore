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


`ifndef PCIE_APP_USCALE_BMD_H
`define PCIE_APP_USCALE_BMD_H

`define PCI_EXP_EP_OUI                          24'h000A35
`define PCI_EXP_EP_DSN_1                        {{8'h1},`PCI_EXP_EP_OUI}
`define PCI_EXP_EP_DSN_2                        32'h10EE0001
`define MSI_INTR                                1

`define C_DEVICE_LEGACY

`ifdef C_DEVICE_LEGACY
`include "pcie_intf_defs_legacy.vh"
`endif // C_DEVICE_LEGACY

`ifdef C_DEVICE_CPM5N
`include "pcie_intf_defs_cpm5n.vh"
`endif // C_DEVICE_CPM5N

`define BMDREG(clk, reset_n, q, d, rstval)  \
   always_ff @(posedge clk) begin \
      if (~reset_n) \
         q  <= #(TCQ)   rstval;  \
      else  \
         q  <= #(TCQ)   d; \
   end

`define AS_BMDREG(clk, reset_n, q, d, rstval)  \
   always_ff @(posedge clk or negedge reset_n) begin \
      if (~reset_n) \
         q  <= #(TCQ)   rstval;  \
      else  \
         q  <= #(TCQ)   d; \
   end

`else    // PCIE_APP_USCALE_BMD_H
`endif   // PCIE_APP_USCALE_BMD_H
