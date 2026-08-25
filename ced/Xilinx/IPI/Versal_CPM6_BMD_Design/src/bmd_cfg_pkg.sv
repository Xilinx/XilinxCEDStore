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

package bmd_cfg_pkg;

localparam int              NUM_VFS             = 64;
localparam int              NUM_PFS             = 8;

localparam logic [2:0]      FUNC_NUM            = 3'b000;
localparam logic [7:0]      VFUNC_NUM           = 8'b0000_0000;
localparam logic [2:0]      BAR_NUM             = 3'b000;
localparam logic            VFUNC_ACTIVE        = 1'b0;

// Bar Size in bytes
localparam int              BAR_SIZE            = 'h1000;

localparam logic            HDR_PROT_CHECK      = 1'b0;
localparam logic            CMP_PARITY_CHECK    = 1'b0;

localparam int              FIFO_DEPTH          = 16;
localparam int              RX_CREDIT_CNT       = FIFO_DEPTH * pcie_str_pkg::NUM_SLOTS;
localparam int              TX_CREDIT_CNT       = 64;

endpackage
