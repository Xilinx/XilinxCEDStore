// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
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

`ifndef IF_PCIE_DMA_FABRIC_OUTPUT_SV
`define IF_PCIE_DMA_FABRIC_OUTPUT_SV
interface dma_pcie_fabric_output_if();
logic            axi_reset_n;
logic            c2h_dsc_avail_inc_vld;
logic  [1:0]     c2h_dsc_avail_inc_chn;
logic  [7:0]     c2h_dsc_avail_inc_qid;
logic  [1:0]     c2h_dsc_avail_inc_state;
logic  [15:0]    c2h_dsc_avail_inc_num;
logic            s_axis_c2h_tstat_vld;
logic  [1:0]     s_axis_c2h_tstat_chn;
logic  [4:0]     s_axis_c2h_tstat_qid;
logic  [7:0]     s_axis_c2h_tstat;
logic  [3:0][7:0]    c2h_sts;
logic  [3:0][7:0]    h2c_sts;
logic            flr_set;
logic            flr_clr;
logic  [7:0]     flr_fnc;
logic  [4:0]     usr_irq_rvec;
logic  [7:0]     usr_irq_rfnc;
logic            usr_irq_fail;
logic            usr_irq_sent;

modport m (
output  axi_reset_n,
output  c2h_dsc_avail_inc_vld,
output  c2h_dsc_avail_inc_chn,
output  c2h_dsc_avail_inc_qid,
output  c2h_dsc_avail_inc_state,
output  c2h_dsc_avail_inc_num,
output  s_axis_c2h_tstat_vld,
output  s_axis_c2h_tstat_chn,
output  s_axis_c2h_tstat_qid,
output  s_axis_c2h_tstat,
output  c2h_sts,
output  h2c_sts,
output  flr_set,
output  flr_clr,
output  flr_fnc,
output  usr_irq_rvec,
output  usr_irq_rfnc,
output  usr_irq_fail,
output  usr_irq_sent
);
modport s (
input  axi_reset_n,
input  c2h_dsc_avail_inc_vld,
input  c2h_dsc_avail_inc_chn,
input  c2h_dsc_avail_inc_qid,
input  c2h_dsc_avail_inc_state,
input  c2h_dsc_avail_inc_num,
input  s_axis_c2h_tstat_vld,
input  s_axis_c2h_tstat_chn,
input  s_axis_c2h_tstat_qid,
input  s_axis_c2h_tstat,
input  c2h_sts,
input  h2c_sts,
input  flr_set,
input  flr_clr,
input  flr_fnc,
input  usr_irq_rvec,
input  usr_irq_rfnc,
input  usr_irq_fail,
input  usr_irq_sent
);
endinterface : dma_pcie_fabric_output_if
`endif
