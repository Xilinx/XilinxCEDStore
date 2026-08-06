
//-----------------------------------------------------------------------------
//
// (c) Copyright 1995, 2007, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : Versal PCI Express Integrated Block
// File       : BMD_AXIST_CFG.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

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
