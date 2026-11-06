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

//==============================================================================
// test_bmd_ide_basic.sv - IDE basic test on the BMD DUT
//==============================================================================
// Description:
//   test_ide_basic (framework) with the link speed / flit mode plusargs the BMD
//   Makefile passes (+CTRLRx_SPEED, +CTRLRx_FM) applied to the VIP (RP) and the
//   DUT (EP), as test_bmd_ep does. Without them the VIP and the DUT do not agree
//   on the target speed and bus enumeration does not complete.
//   Link IDE is enabled (the framework test leaves both streams disabled). The IDE flow
//   itself (keys, stream setup, wait for secure) is unchanged.
//==============================================================================

class test_bmd_ide_basic extends test_ide_basic;
    `uvm_component_utils(test_bmd_ide_basic)

    // Establishes Link IDE (stream 1, TC0), as the reference BMD IDE test
    // does; test_ide_basic leaves both streams disabled by default.
    function new(string name, uvm_component parent);
        super.new(name, parent);
        link_ide_cfg.enable                         = 1'b1;
        link_ide_cfg.pcrc_enable                    = 1'b0;
        link_ide_cfg.partial_header_encryption_mode = 4'b0;
        link_ide_cfg.tc                             = 3'b0;
        link_ide_cfg.stream_id                      = 8'h01;
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        bit [1:0]                  override_fm;
        bit [1:0]                  target_fm;
        bit [1:0]                  override_speed;
        bit [1:0][2:0]             target_speed;
        pcie_config::speed_e [1:0] speed;
        super.end_of_elaboration_phase(phase);

        if ($value$plusargs("CTRLR0_FM=%b", target_fm[0])) override_fm[0] = 1'b1;
        if ($value$plusargs("CTRLR1_FM=%b", target_fm[1])) override_fm[1] = 1'b1;
        if ($value$plusargs("CTRLR0_SPEED=%d", target_speed[0])) override_speed[0] = 1'b1;
        if ($value$plusargs("CTRLR1_SPEED=%d", target_speed[1])) override_speed[1] = 1'b1;

        for (int ii=0; ii<2; ii++) begin
            if (override_speed[ii]) begin
                case (target_speed[ii])
                    1 : speed[ii] = pcie_config::GEN1;
                    2 : speed[ii] = pcie_config::GEN2;
                    3 : speed[ii] = pcie_config::GEN3;
                    4 : speed[ii] = pcie_config::GEN4;
                    5 : speed[ii] = pcie_config::GEN5;
                    6 : speed[ii] = pcie_config::GEN6;
                    default : `uvm_fatal(get_type_name(),
                                $sformatf("Invalid speed passed as plusarg: %d", target_speed[ii]))
                endcase
                vip_cfg.pcie_cfg[ii].pcie_cap.link_ctl2.target_link_speed = speed[ii];
                dut_cfg.pcie_cfg[ii].pcie_cap.link_ctl2.target_link_speed = speed[ii];
            end
            if (override_fm[ii]) begin
                vip_cfg.pcie_cfg[ii].flit_mode_ctl = target_fm[ii];
                dut_cfg.pcie_cfg[ii].flit_mode_ctl = target_fm[ii];
            end
        end
    endfunction

endclass
