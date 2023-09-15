// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
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
// ////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps

`define IO_TRUE                      1
`define IO_FALSE                     0

`define TX_TASKS                     board.RP.tx_usrapp

// Endpoint Sys clock clock frequency 100 MHz -> half clock -> 5000 pS
`define SYS_CLK_COR_HALF_CLK_PERIOD         5000

// Downstrean Port Sys clock clock frequency 250 MHz -> half clock -> 2000 pS
`define SYS_CLK_DSPORT_HALF_CLK_PERIOD      2000

`define RX_LOG                       0
`define TX_LOG                       1

// PCI Express TLP Types constants
`define  PCI_EXP_MEM_READ32          7'b0000000
`define  PCI_EXP_IO_READ             7'b0000010
`define  PCI_EXP_CFG_READ0           7'b0000100
`define  PCI_EXP_COMPLETION_WO_DATA  7'b0001010
`define  PCI_EXP_MEM_READ64          7'b0100000
`define  PCI_EXP_MSG_NODATA          7'b0110xxx
`define  PCI_EXP_MEM_WRITE32         7'b1000000
`define  PCI_EXP_IO_WRITE            7'b1000010
`define  PCI_EXP_CFG_WRITE0          7'b1000100
`define  PCI_EXP_COMPLETION_DATA     7'b1001010
`define  PCI_EXP_MEM_WRITE64         7'b1100000
`define  PCI_EXP_MSG_DATA            7'b1110xxx

`define  RC_RX_TIMEOUT               5000
`define  CQ_RX_TIMEOUT               5000

`define  SYNC_RQ_RDY                 0
`define  SYNC_CC_RDY                 1
