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
