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

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_CFG.sv
//--
//-- Description: Controls any configuration accesses to the CPM core. Primarily
//--              over the dedicated PL DBI interface and config info interface.
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_CFG
  import pcie_intf_pkg::*;
  import bmd_cfg_pkg::*;
  import cpm6_v1_0_pkg::*;
(
    input  logic                            clk,
    input  logic                            rst_n,

    // PF Config Status Info ( from core )
    input  pf_cfg_intf                      pf_cfg,
    // PF Config Status Info ( to user logic )
    output pf_cfg_t [NUM_PFS - 1 : 0]       pf_cfg_regs,
    // VF Config Status Info ( from core )
    input  vf_cfg_intf                      vf_cfg,
    // VF Config Status Info ( to user logic )
    output vf_cfg_t [NUM_VFS - 1 : 0]       vf_cfg_regs
);

localparam logic [1:0]     IDLE   = 2'b11;
localparam logic [1:0]     PF_C_0 = 2'b00;
localparam logic [1:0]     PF_C_1 = 2'b01;
logic [1:0]         state_r, next_state;

pf_cfg_t [NUM_PFS - 1 : 0]             next_pf_cfg_regs;
vf_cfg_t [NUM_VFS - 1 : 0]             next_vf_cfg_regs;

always @(posedge clk) begin
    if(!rst_n) begin
        state_r                 <= IDLE;

        pf_cfg_regs             <= '0;
        vf_cfg_regs             <= '0;
    end else begin
        state_r                 <= next_state;

        pf_cfg_regs             <= next_pf_cfg_regs;
        vf_cfg_regs             <= next_vf_cfg_regs;
    end
end

// PF Logic
always_comb begin
    next_state                  = state_r;

    next_pf_cfg_regs            = pf_cfg_regs;

    unique case (state_r)
        IDLE : begin
            if (pf_cfg.sos) begin
                next_state = PF_C_1; //SOS so go to C1
            end
        end

        PF_C_0 : begin
            if (pf_cfg.pvld) begin
                next_pf_cfg_regs[pf_cfg.func_num].c0    = pf_cfg.info;
                next_state                              = PF_C_1;
            end
        end

        PF_C_1 : begin
            if (pf_cfg.pvld) begin
                next_pf_cfg_regs[pf_cfg.func_num].c1     = pf_cfg.info;
                next_state = PF_C_0;

                if (pf_cfg.sos) begin
                    next_state = PF_C_1; //SOS so go to C1
                end
            end
        end
    endcase
end

// VF Logic
always_comb begin
    next_vf_cfg_regs            = vf_cfg_regs;

    if (vf_cfg.pvld) begin
        next_vf_cfg_regs[vf_cfg.func_num]   = vf_cfg.info;
    end
end

endmodule
