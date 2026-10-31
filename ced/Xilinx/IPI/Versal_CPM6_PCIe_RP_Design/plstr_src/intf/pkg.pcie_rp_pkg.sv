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

package pcie_rp_pkg;

localparam int     NUM_BAR                             = 6;
localparam int     EP_ROM_SIZE                         = 15;
localparam int     RP_ROM_SIZE                         = 9;
localparam int     TRAFFIC_COUNT                       = 200;
localparam int     MAX_PAYLOAD_SIZE                    = 128;
localparam int     ENABLE_EXTENDED_TAG                 = 1;
localparam int     ADDR_WIDTH                          = 64;
localparam int     DATA_WIDTH                          = 32;
localparam int     DW_SIZE                             = 32;
localparam int     ADDR_BUF_DEPTH                      = 64;
localparam int     TX_CREDIT_NUM                       = 64;
localparam int     MAX_PAYLOAD_SIZE_BYTE               = 128;
localparam int     CHECKER_DATA_WIDTH                  = 32;
localparam int     CHECKER_ADDR_WIDTH                  = 7;
localparam int     CHECKER_DEPTH                       = 1024;
localparam int     LOWER_ADDR_WIDTH                    = 7;
localparam int     ERROR_CNT_WIDTH                     = 16;
localparam int     NUM_VFS                             = 256;
localparam int     NUM_PFS                             = 8;
localparam int     PLDBI_ADDR_WIDTH                    = 32;
localparam int     PLDBI_DATA_WIDTH                    = 32;
localparam int     PLDBI_AUSER                         = 11;
localparam int     PLDBI_RESP_USER                     = 4;
localparam int     ACTUAL_PAYLOAD_SIZE_BYTE            = 128;
localparam int     MAX_TAG_COUNT                       = 1024;

endpackage
