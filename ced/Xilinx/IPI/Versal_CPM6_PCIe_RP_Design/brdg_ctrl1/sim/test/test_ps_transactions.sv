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

class test_ps_transactions extends base_rp_test;

  `uvm_component_utils(test_ps_transactions)

  // PL BRAM behind CPM_AXI_PL0 at 0x2_0000_0000, 128K
  // (design_1_bd.tcl, MMIO_APERTURE1 -> CPM_AXI_PL0).
  localparam bit [63:0] BRAM_ADDR_0 = 64'h0000_0002_0000_1000;
  localparam bit [63:0] BRAM_ADDR_1 = 64'h0000_0002_0000_1100;

  // One instance per enabled controller, created in main_phase.
  seq_ps_ep_mem ep_mem_seq;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction


  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
  endfunction

  virtual task pre_configure_phase(uvm_phase phase);
    // Set demux
    `ifdef CPM6_RTL
        demux_sel_vif.set_use_case(PCIE_STR);
    `endif
  endtask

  virtual task main_phase(uvm_phase phase);
    logic [31:0] single_data[];
    int          n_enabled = 0;

    super.main_phase(phase);
    phase.raise_objection(this);

    // One outbound MEM sequence per ENABLED controller, so this test serves
    // ctrl0-only, ctrl1-only and dual designs alike. dut_ctrlr_en comes from
    // the CTRLR0_EN/CTRLR1_EN plusargs and defaults to both enabled.
    foreach (dut_ctrlr_en[i]) if (dut_ctrlr_en[i] === 1'b1) n_enabled++;

    if (n_enabled > 1)
      `uvm_warning(get_type_name, $sformatf(
        {"%0d controllers enabled. Each gets its own outbound map, but they ",
         "SHARE the ECAM base from a single enumeration pass (0x%0h). For a ",
         "true dual-controller run the enumeration must be run per controller ",
         "so each gets its own ECAM (Ctrl0 0x6_0000_0000, Ctrl1 0x7_0000_0000)."},
        n_enabled, bus_enum.ecam_base))

    for (int i = 0; i < 2; i++) begin
      if (dut_ctrlr_en[i] !== 1'b1) continue;

      ep_mem_seq = seq_ps_ep_mem::type_id::create($sformatf("ep_mem_seq_ctrl%0d", i));
      {ep_mem_seq.ecam_base, ep_mem_seq.bus_base} = {bus_enum.ecam_base, bus_enum.bus_base};
      // Sets the iATU register bases; without it seq_ps_pcie_enum::pre_body()
      // fatals on ctrlr === 1'bx.
      ep_mem_seq.set_ctrlr(i[0]);

      // Type 1 windows sized from this controller's BARs, plus MSE+BME, all
      // over ECAM. Stock framework, no fork.
      ep_mem_seq.program_rp_bridge = 1'b1;

      `uvm_info(get_type_name, $sformatf(
        "=== Outbound MEM sequence: Controller %0d ===", i), UVM_LOW)
      ep_mem_seq.start(env.shim.vsqr.ps_vip_vsqr);
    end

    // Inbound egresses toward the NoC: MMIO_APERTURE0 (0x0-0xffff_ffff,
    // DEST = PCIE_AXI_NOC0) -> axi_noc2_0/S09_AXI -> M01_AXI ->
    // ps_wizard_0/NOC_AXI_PMC0. The VIP models no address decode and allows
    // exactly one destination per source.
    ps_vip_api.set_routing_config(CPM_PS_AXI_0, PS_NOC_PCI_AXI_0, 1'b1);
    `uvm_info(get_type_name, "PS VIP routing configured: CPM_PS_AXI_0 -> PS_NOC_PCI_AXI_0", UVM_LOW)


    #2us;

    #10us;

    // Inbound EP -> RP -> PL BRAM: write a known pattern over PCIe and read
    // the same bytes back.
    //
    // Every inbound target must be below 0x8000_0000 or inside the PL
    // aperture at 0x2_0000_0000. An address outside both is claimed by
    // nothing, never returns, and head-of-line blocks all inbound traffic
    // behind it.
    ep_mem_wr_rd(BRAM_ADDR_0, 32'hA5A5A5A5, "BRAM_ADDR_0");
    ep_mem_wr_rd(BRAM_ADDR_1, 32'h12341234, "BRAM_ADDR_1");

    rp_bridge_log::summary();

    phase.drop_objection(this);

  endtask

  virtual task send_ep_memory_write(
    bit [63:0] addr,
    bit [31:0] data[],
    int port_id = 0
    );
    amd_mem_tlp mem_tlp;

    mem_tlp = amd_mem_tlp::type_id::create("mem_tlp");

    // Parameters: addr, length, data, f_be, l_be, blocking, default_data
    mem_tlp.build_wr(
      .addr(addr),
      .length(data.size()),  // or specify length explicitly
      .data(data),
      .f_be(4'hF),           // First byte enable (all bytes)
      .l_be(4'hF),           // Last byte enable (all bytes)
      .blocking(NONBLOCK)    // or BLOCK for blocking behavior
    );

    env.shim.api.send_mem(mem_tlp);

    `uvm_info(get_type_name,
              $sformatf("Sent EP memory write to addr 0x%0h with %0d DWs",
                        addr, data.size()), UVM_LOW)
  endtask

  virtual task send_ep_memory_read(
    bit [63:0] addr,
    bit [31:0] data[],
    int port_id = 0
    );
    amd_mem_tlp mem_tlp;

    mem_tlp = amd_mem_tlp::type_id::create("mem_tlp");

    // Parameters: addr, length, data, f_be, l_be, blocking, default_data
    mem_tlp.build_rd(
      .addr(addr),
      .length(data.size()),  // or specify length explicitly
      .f_be(4'hF),          // First byte enable (all bytes)
      .l_be(4'hF),          // Last byte enable (all bytes)
      .blocking(NONBLOCK)   // or BLOCK for blocking behavior
    );

    env.shim.api.send_mem(mem_tlp);

    `uvm_info(get_type_name,
              $sformatf("Sent EP memory read to addr 0x%0h expecting %0d DWs",
                        addr, data.size()), UVM_LOW)
  endtask

  // Write then read one dword over PCIe and compare. blocking(DONE) makes the
  // read return its payload, so this is a real check, not just a completion.
  virtual task ep_mem_wr_rd(bit [63:0] addr, bit [31:0] expected, string tag);
    amd_mem_tlp mem_tlp;
    bit [31:0]  wr_data[];

    wr_data    = new[1];
    wr_data[0] = expected;

    mem_tlp = amd_mem_tlp::type_id::create("bram_wr");
    mem_tlp.build_wr(.addr(addr), .data(wr_data), .f_be(4'hF), .l_be(4'hF),
                     .blocking(DONE));
    env.shim.api.send_mem(mem_tlp);

    #1us;

    mem_tlp = amd_mem_tlp::type_id::create("bram_rd");
    mem_tlp.build_rd(.addr(addr), .length(1), .f_be(4'hF), .l_be(4'hF),
                     .blocking(DONE));
    env.shim.api.send_mem(mem_tlp);

    if (mem_tlp.data.size() == 0)
      `uvm_error(get_type_name, $sformatf("INBOUND[%0s @0x%0h] completion carried NO payload",
                                          tag, addr))
    else if (mem_tlp.data[0] !== expected)
      `uvm_error(get_type_name, $sformatf("INBOUND[%0s @0x%0h] = 0x%08h, expected 0x%08h",
                                          tag, addr, mem_tlp.data[0], expected))
    else
      `uvm_info(get_type_name, $sformatf("INBOUND[%0s @0x%0h] = 0x%08h *** MATCH ***",
                                         tag, addr, mem_tlp.data[0]), UVM_LOW)

    rp_bridge_log::tally(.is_match(mem_tlp.data.size() != 0 &&
                                   mem_tlp.data[0] === expected), .is_ur(1'b0));
    `rp_txn($sformatf("  IN   0x%012h  %-11s  0x%08h  %-10s  %s",
            addr, rp_bridge_log::target_of(addr), expected,
            (mem_tlp.data.size() == 0) ? "----------" : $sformatf("0x%08h", mem_tlp.data[0]),
            (mem_tlp.data.size() == 0) ? "NO PAYLOAD" :
            (mem_tlp.data[0] === expected) ? "MATCH" : "MISMATCH"))
  endtask

endclass
