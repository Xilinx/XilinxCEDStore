//////////////////////////////////////////////////////////////////////////////
// be767e8644eee50b2645307571242b99d62eea726bb276dae1cba7a07fa60690
// Proprietary Note:
// XILINX CONFIDENTIAL
//
// Copyright 2017 Xilinx, Inc. All rights reserved.
// This file contains confidential and proprietary information of Xilinx, Inc.
// and is protected under U.S. and international copyright and other
// intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
// US ExportControl: EAR 3E001
//
//       Owner:          
//       Revision:       $Id: //IP3/DEV/hw/pcie_gen4/rtl_ev/pciea_dma/rtl/pciea_dma.sv#56 $
//                       $Author: cthyamag $
//                       $DateTime: 2017/05/12 10:48:36 $
//                       $Change: 1878059 $
//       Description:
//
//////////////////////////////////////////////////////////////////////////////

`ifndef IF_PCIE_DMA_C2H_AXIS_SV
`define IF_PCIE_DMA_C2H_AXIS_SV
`timescale 1 ps / 1 ps
interface dma_pcie_c2h_axis_if#()();
logic  [511:0]       tdata;
logic  [512/8-1:0]   tparity;
logic                tlast;
logic                tvalid;
logic  [512/8-1:0]   tkeep;
logic                tready;
logic  [63:0]        tusr;

modport m (
output     tdata,
output     tparity,
output     tlast,
output     tvalid,
output     tkeep,
output     tusr,
input      tready
);

modport s (
input       tdata,
input       tparity,
input       tlast,
input       tvalid,
input       tkeep,
input       tusr,
output      tready
);
endinterface : dma_pcie_c2h_axis_if
`endif
