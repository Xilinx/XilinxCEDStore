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

package cfg_status_pkg;

`define STRUCT_PF_CFG_0
typedef struct packed {
    logic               flr_pf_active;          // 15
    logic               rcb;                    // 14
    logic               ext_tag_en;             // 13
    logic [2:0]         max_payload_size;       // 12:10
    logic [2:0]         max_rd_req_size;        // 9:7
    logic               atomic_req_en;          // 6
    logic               pf_pasid_en;            // 5
    logic               msix_func_mask;         // 4
    logic               msix_en;                // 3
    logic               msi_en;                 // 2
    logic               mem_space_en;           // 1
    logic               bus_master_en;          // 0
} pf_cfg_0_t;

`define STRUCT_PF_CFG_1
typedef struct packed {
    logic               flit_mode;              // 15
    logic               pm_turnoff;             // 14
    logic [2:0]         reserved;               // 13:11
    logic [1:0]         tph_req_en;             // 10:9
    logic               prs_en;                 // 8
    logic               ats_cache_en;           // 7
    logic               pasid_priv_mode_en;     // 6
    logic               pasid_execute_perm_en;  // 5
    logic               io_space_en;            // 4
    logic               pm_status;              // 3
    logic               int_disable;            // 2
    logic               vf_en;                  // 1
    logic               tenb_tag_req_en;        // 0
} pf_cfg_1_t;

`define STRUCT_PF_CFG
typedef struct packed {
    pf_cfg_0_t          c0;
    pf_cfg_1_t          c1;
} pf_cfg_t;

`define UNION_PF_CFG
typedef union packed {
    pf_cfg_0_t          c0;
    pf_cfg_1_t          c1;
} pf_cfg_u_t;

`define STRUCT_PF_CFG_IF
typedef struct {
    logic               pvld;
    pf_cfg_u_t          info;
    logic               sos;
    logic [2:0]         func_num;
} pf_cfg_intf;

`define STRUCT_VF_CFG
typedef struct packed {
    logic               flr_vf_active;          // 4
    logic               vf_msix_func_mask;       // 3
    logic               vf_msix_en;             // 2
    logic               vf_msi_en;              // 1
    logic               vf_bme;                 // 0
} vf_cfg_t;

`define STRUCT_VF_CFG_IF
typedef struct {
    logic               pvld;
    vf_cfg_t            info;
    logic               sos;
    logic [7:0]         func_num;
} vf_cfg_intf;

endpackage