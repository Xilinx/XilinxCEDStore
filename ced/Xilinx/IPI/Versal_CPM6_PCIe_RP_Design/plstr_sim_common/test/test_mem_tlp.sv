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

import test_param_pkg::*;

class test_mem_tlp extends base_rp_test;

  `uvm_component_utils(test_mem_tlp);

  amd_mem_tlp     tlp;

  rp_env         _rp_env;

  // Custom callback class
  class my_custom_cfgspc_cb extends apci_callbacks;
    int port_id;
    generic_config cfg;
    int rand_idx;
    logic [5:0][31:0] bar_array;
    
    function new();
      // Initialize BAR array based on IS_64BIT_BAR parameter
        bar_array = '{
          32'h000003FF,  // BAR 0: 1KB   (2^10)
          32'h00000FFF,  // BAR 1: 4KB   (2^12)
          32'h00001FFF,  // BAR 2: 8KB   (2^13)
          32'h0001FFFF,  // BAR 3: 128KB (2^17)
          32'h000FFFFF,  // BAR 4: 1MB   (2^20)
          32'h003FFFFF   // BAR 5: 4MB   (2^22)
        };
    endfunction
    
    virtual function void setup_cfg_space(input apci_device bfm, input apci_cfg_space csp);
      bit [1:0] pid = this.port_id;
      $display("[%0t] MY_CB: In setup_cfg_space callback for Port %0d", $time, pid);
      if (pid==csp.port_id && cfg.ctrlr_en[pid]) begin
        
        // Your custom configuration here
        if (cfg.pcie_cfg[pid].pcie_cap.pcie_cap.dev_port_type == pcie_config::EP) begin
          $display("[%0t] MY_CB: EP Port %0d: Setting random BAR sizes", $time, pid);
          //BAR settings
          if(IS_64BIT_BAR == 1) begin
            for(int i=0; i<3; i++) begin
              csp.type0.bars[i*2].set_dv(4); // 64-bit Memory Space Indicator
              csp.type0.bars[i*2+1].set_dv(0); // Upper 32 bits of 64-bit BAR
              rand_idx = $urandom_range(0, 2);
              csp.type0.bars[i*2].set_write_mask(32'hffffffff);
              csp.type0.bars[i*2+1].set_write_mask(bar_array[rand_idx]);
            end
          end else begin
            for(int i=0; i<6; i++) begin
              csp.type0.bars[i].set_dv(0); // Memory Space Indicator
              rand_idx = $urandom_range(0, 5);
              csp.type0.bars[i].set_write_mask(bar_array[rand_idx]);
            end
          end
          // MSI-X Table/PBA live in a BAR, not config space, so they exist regardless
          // of the Enable bit. table_size is 0's-based: 0 = one vector (16B), minimum.
          // BIR 5 puts them on the highest BAR, away from the traffic generator.
          csp.msix.table_size.set_dv(0);
          csp.msix.table_bir.set_dv(5);
          csp.msix.pba_bir.set_dv(5);
          $display("[%0t] MY_CB: Port %0d: MSI-X minimised (1 vector) and relocated to BAR5", $time, pid);
        end
        else begin
          // Custom RP BAR configuration
          csp.type0.bars[0].set_dv(32'hff00_000C);  // 64-bit prefetchable
          csp.type0.bars[0].set_write_mask(32'h00ff_ffff);  // 16MB
          $display("[%0t] MY_CB: RP Port %0d: BAR0 set to 16MB 64-bit prefetchable", $time, pid);
        end
      end
    endfunction
  endclass

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  bit [1:0] ctrlr_fm = 2'b11;   // resolved in build_phase, applied in end_of_elaboration

  int exp_gen   = 6;
  // Negotiated rate, sampled after all traffic has completed. -1 = not sampled.
  int final_gen = -1;
  // Link width of the controller this design brings up, resolved in
  // post_enum_seq and reused by the RESULT block.
  int lnk_width = 0;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "Starting build phase in test_mem_tlp", UVM_LOW)

    for (int ii = 0; ii < 2; ii++) begin
      bit fm;
      if (!$value$plusargs($sformatf("CTRLR%0d_FM=%%b", ii), fm)) fm = 1'b1;
      ctrlr_fm[ii] = fm;
    end
    // Same pattern for the configured Gen. Both controllers get the same value.
    for (int ii = 0; ii < 2; ii++) begin
      int g;
      if ($value$plusargs($sformatf("CTRLR%0d_SPEED=%%d", ii), g)) exp_gen = g;
    end

    // One key: this design enables a single controller and the Makefile passes
    // the same value to both.
    uvm_config_db#(int)::set(null, "*", "flit_mode", int'(ctrlr_fm[1]));
    `uvm_info(get_type_name(), $sformatf("Flit mode: ctrlr0 = %0d, ctrlr1 = %0d",
                                         ctrlr_fm[0], ctrlr_fm[1]), UVM_LOW)

    _rp_env = rp_env::type_id::create("_rp_env", this);
    if (!_rp_env)
        `uvm_fatal(get_type_name(), "Failed to create rp_env")
    `uvm_info(get_type_name(), "Completed build phase in test_mem_tlp", UVM_LOW)
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    env.shim.vip.ap_rx_pkt_enter_tl.connect(_rp_env.sb.rxp);
    env.shim.vip.ap_tx_pkt_exit_tl.connect(_rp_env.sb.txp);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
      bus_enum.skip_enum_seq = 1'b1;
      for (int ii=0; ii<2; ii++) begin
        dut_cfg.pcie_cfg[ii].flit_mode_ctl = ctrlr_fm[ii];
        vip_cfg.pcie_cfg[ii].flit_mode_ctl = ctrlr_fm[ii];

        dut_cfg.port_ctl[ii] = generic_config::PCIE;
        vip_cfg.port_ctl[ii] = generic_config::PCIE;
        dut_cfg.cxl_cfg[ii].rand_mode(0);
        vip_cfg.cxl_cfg[ii].rand_mode(0);
        dut_cfg.cxl_cfg[ii].cxl_device_type = 1;
        vip_cfg.cxl_cfg[ii].cxl_device_type = 1;
    end
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    my_custom_cfgspc_cb my_cb;
    super.start_of_simulation_phase(phase);
      my_cb = new();
      my_cb.port_id = 0;  // Controller 0
      my_cb.cfg = vip_cfg;
      env.shim.vip.append_callback(my_cb);
      `uvm_info(get_type_name(), "Appended custom cfg space callback", UVM_LOW)
  endfunction

  virtual task pre_configure_phase(uvm_phase phase);
    // Set demux
`ifdef CPM6_RTL
     demux_sel_vif.set_use_case(PCIE_STR);
`endif
  endtask

  virtual task post_enum_seq();
    int    enum_us_exp;
    time   enum_time_exp;

    // Avery treats timeout=0 as "wait forever", so these must be assigned or the
    // link checks below can never fire.
    enum_us_exp   = 250;
    enum_time_exp = enum_us_exp * 1us;

    super.post_enum_seq(); // optional; safe to keep
    `uvm_info(get_type_name(), "post_enum_seq from test_mem_tlp", UVM_LOW)

    while(env.shim.vip.port_get(0, "current_speed") < 3) begin
      #1ns;
    end

    `uvm_info(get_type_name(), $sformatf("PCIe link speed is gen%0d", env.shim.vip.port_get(0, "current_speed")), UVM_MEDIUM)
    // Wait for link to come up
    env.shim.vip.port_wait_event(0, "link_up", enum_time_exp, "PCIe link never came up");
    `uvm_info(get_type_name(), "PCIe link is now up", UVM_MEDIUM)

    // Wait for L0
    env.shim.vip.port_wait_event(0, "L0", enum_time_exp, "PCIe link never entered L0");
    `uvm_info(get_type_name(), "PCIe link is now in L0", UVM_MEDIUM)

    begin
      string fm_str;
      int    ctrl_num;
      bit    en;

      ctrl_num = 1;
      if ($value$plusargs("CTRLR0_EN=%b", en) && en == 0) ctrl_num = 1;
      if ($value$plusargs("CTRLR1_EN=%b", en) && en == 0) ctrl_num = 0;

      // Not a ternary: SystemVerilog pads the shorter string literal arm.
      if (ctrlr_fm[ctrl_num]) fm_str = "flit mode"; else fm_str = "non-flit mode";

      lnk_width = rp_link_pkg::LINK_WIDTH;

      `rp_note("CONFIG", "=========== RP PL-streaming test configuration ===========")
      `rp_note("CONFIG", $sformatf("  Controller    : %0d", ctrl_num))
      `rp_note("CONFIG", $sformatf("  Link          : Gen%0d x%0d, %s",
                exp_gen, lnk_width, fm_str))
      `rp_note("CONFIG", $sformatf("  Traffic count : %0d memory reads, %0d DW each",
                pcie_rp_pkg::TRAFFIC_COUNT, pcie_rp_pkg::MAX_PAYLOAD_SIZE/4))
      `rp_note("CONFIG", $sformatf("  ROM           : RP %0d entries, EP %0d entries",
                pcie_rp_pkg::RP_ROM_SIZE, pcie_rp_pkg::EP_ROM_SIZE))
      `rp_note("CONFIG", $sformatf("  BARs          : %0d, bases assigned by the RP during enumeration",
                pcie_rp_pkg::NUM_BAR))
      `rp_note("CONFIG", $sformatf("  Credits       : TX %0d, RX %0d (%0d slots x 16)",
                pcie_rp_pkg::TX_CREDIT_NUM,
                16*pcie_str_pkg::RX_NUM_SLOTS, pcie_str_pkg::RX_NUM_SLOTS))
      `rp_note("CONFIG", "=========================================================")
    end

  endtask


  virtual task main_phase(uvm_phase phase);
    vseq_loop  seq_loop;
    

    super.main_phase(phase);
    phase.raise_objection(this);
    #1us;

    `uvm_info(get_type_name(), $sformatf("number of pdevs = %0d",env.shim.container.pdev.size), UVM_HIGH)
    
    // Print all pdevs in container
    for (int i = 0; i < env.shim.container.pdev.size; i++) begin
      `uvm_info(get_type_name(), $sformatf("pdev[%0d]: %s", i, env.shim.container.pdev[i].sprint()), UVM_HIGH)
    end
    
    fork
      begin
        #200us;
      end
      begin
        while(_rp_env.mem_sb.mem_rd_count < pcie_rp_pkg::TRAFFIC_COUNT) begin
          #100ns; // Small delay to avoid busy waiting
        end
        `uvm_info(get_type_name(), $sformatf("Reached target memory read count: %0d", _rp_env.mem_sb.mem_rd_count), UVM_NONE);
      end        
    join_any
    disable fork;
    #5us;
    // #50ms;

    // All traffic has completed, so the link is settled - this is the only
    // point where the negotiated rate can be read without racing training.
    final_gen = env.shim.vip.port_get(0, "current_speed");

    phase.drop_objection(this);
  endtask 

endclass