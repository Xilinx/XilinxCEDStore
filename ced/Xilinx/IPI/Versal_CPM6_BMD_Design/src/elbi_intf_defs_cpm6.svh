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

`ifndef ELBI_INTF_DEFS_CPM6_SV
`define ELBI_INTF_DEFS_CPM6_SV

interface elbi_intf_defs_cpm6 ();
logic             ext_lbc_override_en;
logic  [7:0]      ext_lbc_ack;
logic  [63:0]     ext_lbc_din;
logic  [31:0]     lbc_ext_addr;
logic  [63:0]     lbc_ext_dout;
logic  [7:0]      lbc_ext_valid;
logic  [7:0]      lbc_ext_cs;
logic  [7:0]      lbc_ext_wr;
logic  [7:0]      lbc_ext_rd;
logic             lbc_ext_dbi_access;
logic             lbc_ext_cxl_mbar0_access;
logic             lbc_ext_rom_access;
logic             lbc_ext_io_access;
logic  [2:0]      lbc_ext_bar_num;
logic  [7:0]      lbc_ext_vfunc_num;
logic             lbc_ext_vfunc_active;

modport master (
   input             ext_lbc_override_en,
   input             ext_lbc_ack,
   input             ext_lbc_din,
   output            lbc_ext_addr,
   output            lbc_ext_dout,
   output            lbc_ext_valid,
   output            lbc_ext_cs,
   output            lbc_ext_wr,
   output            lbc_ext_rd,
   output            lbc_ext_dbi_access,
   output            lbc_ext_cxl_mbar0_access,
   output            lbc_ext_rom_access,
   output            lbc_ext_io_access,
   output            lbc_ext_bar_num,
   output            lbc_ext_vfunc_num,
   output            lbc_ext_vfunc_active
);

modport slave (
   output            ext_lbc_override_en,
   output            ext_lbc_ack,
   output            ext_lbc_din,
   input             lbc_ext_addr,
   input             lbc_ext_dout,
   input             lbc_ext_valid,
   input             lbc_ext_cs,
   input             lbc_ext_wr,
   input             lbc_ext_rd,
   input             lbc_ext_dbi_access,
   input             lbc_ext_cxl_mbar0_access,
   input             lbc_ext_rom_access,
   input             lbc_ext_io_access,
   input             lbc_ext_bar_num,
   input             lbc_ext_vfunc_num,
   input             lbc_ext_vfunc_active
);


endinterface : elbi_intf_defs_cpm6
`endif