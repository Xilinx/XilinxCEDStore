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

// PL_Streaming IDE test: test_rp_traffic, but the RTL (IDE_EN) holds the memory
// traffic until the RP reports a Secure IDE stream, so the IDE bring-up runs in
// parallel with the traffic wait. The IDE flow is test_ide_basic's backdoor flow
// with the DUT as Root Port (see rp_ide_helper). Enabled with IDE=true; the
// Makefile selects it by default.
class test_rp_ide_basic extends test_rp_traffic;

  `uvm_component_utils(test_rp_ide_basic)

  rp_ide_helper ide_helper;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    // The RTL polls the RP IDE status every ms; leave room for it
    traffic_timeout = 5ms;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ide_helper = rp_ide_helper::type_id::create("ide_helper", this);
  endfunction

  virtual task ide_bringup();
    ide_helper.env    = env;
    ide_helper.ep_bdf = test_param_pkg::TEST_BDF;
    // As the firmware does: ECAM-style accesses through the PL config bridge (M00_AXI_0), reached from
    // the R5 through the NoC, at the window the R5s see it (0xE000_0000, 256 MB)
    ide_helper.ep_cfg_addr = 48'hE000_0000 + (test_param_pkg::TEST_BDF << 12);
    ide_helper.ep_cfg_mst  = FPD_AXI_NOC_1;
    ide_helper.vip_force_secure = 1'b1;
    // Link IDE protects the config requests too, so the Endpoint is enabled first (the write is still clear)
    for (int i = 0; i < 2; i++)
      if (dut_ctrlr_en[i] === 1'b1) ide_helper.ctrlr = i[0];
    ide_helper.run_ide_bringup();
  endtask

  // The bridge's config reads (IDE bring-up) are counted by the RTL's checker but not by the scoreboards
  virtual function bit data_mismatch_exact();
    return 1'b0;
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    ide_helper.check_ide_traffic(1'b1);
  endfunction

endclass
