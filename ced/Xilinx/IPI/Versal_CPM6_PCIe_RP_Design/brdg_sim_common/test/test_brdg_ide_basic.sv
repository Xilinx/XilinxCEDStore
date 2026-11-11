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

// AXI_Bridge IDE test: test_ps_transactions with an IDE bring-up between the
// outbound sequences (enumeration, RP bridge windows) and the inbound
// EP -> RP -> DDR/BRAM traffic, which therefore runs over the secured link.
// The IDE flow is test_ide_basic's backdoor flow with the DUT as Root Port
// (see rp_ide_helper). Enabled with IDE=true; the Makefile selects it by default.
class test_brdg_ide_basic extends test_ps_transactions;

  `uvm_component_utils(test_brdg_ide_basic)

  rp_ide_helper ide_helper;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ide_helper = rp_ide_helper::type_id::create("ide_helper", this);
  endfunction

  virtual task pre_inbound_traffic();
    pcie_device pdev_ep;
    super.pre_inbound_traffic();

    ide_helper.env = env;
    for (int i = 0; i < 2; i++)
      if (dut_ctrlr_en[i] === 1'b1) ide_helper.ctrlr = i[0];

    pdev_ep = env.shim.container.get_pdev_EP;
    // The Endpoint sits on the bus behind the RP (bus_base + 1, device 0), as seq_ps_ep_mem enumerates it
    ide_helper.ep_bdf      = {bus_enum.bus_base + 8'd1, 8'h00};
    `uvm_info(get_type_name, $sformatf("EP BDF 0x%04h (enumeration reports 0x%04h), ECAM base 0x%0h",
              ide_helper.ep_bdf, pdev_ep.bdf, bus_enum.ecam_base), UVM_LOW)
    // As the firmware does: the RP reaches the EP's config space through the ECAM
    ide_helper.ep_cfg_addr = bus_enum.ecam_base + (ide_helper.ep_bdf << 12);
    ide_helper.ep_cfg_mst  = PS_CPM_CFG;
    ide_helper.vip_force_secure = 1'b1;

    ide_helper.run_ide_bringup();
    // From here on the Endpoint's memory requests (the base test's inbound traffic) go out on the IDE stream
    ide_stream_id = ide_helper.link_ide_cfg.enable ? ide_helper.link_ide_cfg.stream_id : ide_helper.sel_ide_cfg.stream_id;
  endtask

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    // base test traffic: 2 DDR + 2 BRAM inbound read/write pairs: 8 protected requests EP->RP, 4 protected completions RP->EP
    ide_helper.check_ide_traffic(1'b0, 4, 8);
  endfunction

endclass
