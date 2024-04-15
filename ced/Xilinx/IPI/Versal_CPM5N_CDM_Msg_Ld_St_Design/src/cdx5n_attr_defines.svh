//-----------------------------------------------------------------------------
//
// (c) Copyright 1986-2022 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
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
//-----------------------------------------------------------------------------
`ifndef CDX_ATTR_DEFINES_SVH
`define CDX_ATTR_DEFINES_SVH

typedef logic    [31:0] attr_reg_t;

typedef struct packed {
    attr_reg_t [15:0] attr;
} attr_csi_t;

typedef struct packed {
    attr_reg_t [1:0] attr;
} attr_top_t;

typedef struct packed {
    attr_reg_t [1:0] attr;
} attr_fab_t;

typedef struct packed {
    attr_reg_t       attr;
} attr_hah_t;

typedef struct packed {
    attr_reg_t [1:0] attr;
} attr_pcie_brg_t;

typedef struct packed {
    attr_reg_t [3:0] attr;
} attr_psx_brg_t;

typedef struct packed {
    attr_reg_t [3:0] attr; 
} attr_cdm_t;

typedef struct packed {
    attr_reg_t [7:0] attr; 
} attr_qdma_t;

typedef struct packed {
    attr_top_t      top;  // Needed? or have duplicate attr in submodules if needed
    attr_fab_t      fab;
    attr_hah_t      hah;
    attr_csi_t      csi;
    attr_pcie_brg_t [3:0] pcie_brg;
    attr_psx_brg_t  psx_brg;
    attr_cdm_t      cdm;
    attr_qdma_t     qdma;
} attr_in_cdx_t;

typedef struct packed {
    attr_reg_t [3:0] pcie_brg;
} attr_out_cdx_t;




`endif
