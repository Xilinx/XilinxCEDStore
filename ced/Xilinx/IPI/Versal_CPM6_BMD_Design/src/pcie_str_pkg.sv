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

package pcie_str_pkg;

localparam logic            WIDE_MODE = 1'b1;
localparam int              NUM_SLOTS = 3;
localparam int              MAX_NUM_SLOTS = 3;
localparam int              MAX_SUB_SLOTS = 3;

localparam int              DATA_SLOT_WIDTH = 512;
localparam int              DATA_SLOT_WIDTH2 = DATA_SLOT_WIDTH * 2;
localparam int              DATA_SLOT_WIDTH3 = DATA_SLOT_WIDTH * 3;
localparam int              TX_SLOT_WIDTH = 852;
localparam int              RX_SLOT_WIDTH = 885;

localparam int              RX_NP_SLOT_WIDTH = RX_SLOT_WIDTH / MAX_SUB_SLOTS;
localparam int              TX_NP_SLOT_WIDTH = TX_SLOT_WIDTH / MAX_SUB_SLOTS;

localparam int              PARITY_CHUNK = 64;
localparam int              TX_PARITY_WIDTH = (TX_SLOT_WIDTH * MAX_NUM_SLOTS + PARITY_CHUNK - 1) / PARITY_CHUNK;
localparam int              RX_PARITY_WIDTH = (RX_SLOT_WIDTH * MAX_NUM_SLOTS + PARITY_CHUNK - 1) / PARITY_CHUNK;

localparam int              START_PTR_WIDTH = $clog2(NUM_SLOTS);
localparam int              START_TYPE_WIDTH = 2;
localparam int              START_NP_INFO_WIDTH = MAX_SUB_SLOTS;

localparam int              END_PTR_WIDTH = $clog2(NUM_SLOTS);
localparam int              END_DPTR_WIDTH = $clog2(DATA_SLOT_WIDTH/32);
localparam int              END_ERROR_WIDTH = 9;

localparam logic [7:0][6:0] credit_encoding = {7'd64, 7'd32, 7'd16, 7'd8, 7'd4, 7'd2, 7'd1, 7'd0};

endpackage
