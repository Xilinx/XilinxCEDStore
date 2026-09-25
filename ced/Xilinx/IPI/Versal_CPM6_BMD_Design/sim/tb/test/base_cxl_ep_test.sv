/* DESCRIPTION
 * This class configures the VIP as CXL RP and DUT as CXL EP and instructs both 
 * to link up in CXL mode. After enumeration, there is a check that the link
 * came up at the desired speed and in CXL mode. Further configuration is
 * required in extended tests to set up the DUT. 
 * EXTENDS
 * test_enum
 * ACRONYMS
|*/

// Foward declaration of callback
typedef class seq_enum_cb;

class base_cxl_ep_test extends test_enum;

  `uvm_component_utils(base_cxl_ep_test)

  logic [1:0] dut_ctrlr_en;

  // This controls the advertised speeds supported in TSs, which must be at 
  // least Gen5 for Alt. Prot. Neg. to occur (sls="supported link speeds")
  rand pcie_config::speed_e rp_sls[0:1];

  constraint c_rp_sls { 
    foreach (rp_sls[ii]) rp_sls[ii] inside {pcie_config::GEN5, 
                                            pcie_config::GEN6}; 
  }

  // Ensure link operates at any CXL compatible rate
  rand bit [2:0] cxl_link_speed[0:1];
  // Ensure CXL.mem and CXL.cache capable are advertised correctly
  rand bit [1:0] cxl_dev_type[0:1];

  constraint c_cxl_host_capability{
    foreach (cxl_dev_type[ii]) cxl_dev_type[ii] inside {2,3};
  }

  constraint c_cxl_nfm{
    solve rp_sls before cxl_link_speed;
    foreach (cxl_link_speed[ii]) {
      rp_sls[ii]==pcie_config::GEN5 -> cxl_link_speed[ii] inside {[3:5]};
      rp_sls[ii]==pcie_config::GEN6 -> cxl_link_speed[ii] inside {[3:6]};
    }
  }

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    seq_enum_cb bus_enum_cb = seq_enum_cb::type_id::create("bus_enum_cb");
    super.end_of_elaboration_phase(phase);
    // Default each DUT controller to enabled, which affects CDO programming
    // Extended tests should set these members before this phase
    if (!$value$plusargs("CTRLR0_EN=%b",dut_ctrlr_en[0]) && dut_ctrlr_en[0]===1'bx)
      dut_ctrlr_en[0] = 1'b1;
    if (!$value$plusargs("CTRLR1_EN=%b",dut_ctrlr_en[1]) && dut_ctrlr_en[1]===1'bx)
      dut_ctrlr_en[1] = 1'b1;
    // Perform some initial randomization and disable them re-randomizing
    void'(this.randomize());
    for (int ii=0; ii<2; ii++) begin
      rp_sls[ii].rand_mode(0);
      cxl_dev_type[ii].rand_mode(0);
      cxl_link_speed[ii].rand_mode(0);
    end
    //  Register the callback for enumeration
    bus_enum_cb.cxl_link_speed = cxl_link_speed;
    uvm_callbacks#(seq_enum, seq_enum_callback)::add(bus_enum, bus_enum_cb);
    // -- //
    for (int ii=0; ii<2; ii++) begin
      // VIP as RP
      vip_cfg.ctrlr_en[ii] = dut_ctrlr_en[ii];
      vip_cfg.port_ctl[ii] = generic_config::PCIE_CXL;
      vip_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::RP;
      vip_cfg.pcie_cfg[ii].pcie_cap.link_ctl2.target_link_speed = rp_sls[ii];
      vip_cfg.pcie_cfg[ii].flit_mode_ctl = 1'b1;
      vip_cfg.cxl_cfg [ii].cxl_device_type = cxl_dev_type[ii];
      // DUT as EP
      dut_cfg.ctrlr_en[ii] = dut_ctrlr_en[ii];
      dut_cfg.use_case[ii] = dut_config::CXL_STR;
      dut_cfg.port_ctl[ii] = generic_config::PCIE_CXL;
      dut_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::EP;
    end
    // RTL sims need CDO
    if ($test$plusargs("CPM6_RTL")) begin
      dut_cfg.base_cdo = "cpm6_ep_cxl3_g6x8.cdo.anno"; 
    end
  endfunction

  // Check to make sure link came up in CXL mode at targeted speed
  virtual task post_enum_seq();
    bit [7:0] curr_speed, curr_lw; 
    bit port_id;
    super.post_enum_seq();
    // -- //
    if (dut_cfg.ctrlr_en[0]) begin
      port_id = 0;
      curr_speed = env.shim.vip.port_get(port_id, "current_speed");
      curr_lw    = env.shim.vip.port_get(port_id, "current_linkwidth");
      if (!env.shim.vip.port_get(port_id, "cxl_mode_active"))
        `uvm_fatal(get_type_name, "Link 0 did not come up in CXL mode")
      else if (curr_speed != cxl_link_speed[0])
        `uvm_error(get_type_name, $sformatf("Link 0 targeted Gen %0d, resolved to Gen %0d", cxl_link_speed[0], curr_speed))
      else 
        `uvm_info(get_type_name, $sformatf("Link 0 in CXL mode at Gen %0dx%0d", curr_speed, curr_lw), UVM_NONE)
    end
    // -- //
    if (dut_cfg.ctrlr_en[1]) begin
      port_id = dut_cfg.ctrlr_en[0];
      curr_speed = env.shim.vip.port_get(port_id, "current_speed");
      curr_lw    = env.shim.vip.port_get(port_id, "current_linkwidth");
      if (!env.shim.vip.port_get(port_id, "cxl_mode_active"))
        `uvm_fatal(get_type_name, "Link 1 did not come up in CXL mode")
      else if (curr_speed != cxl_link_speed[1])
        `uvm_error(get_type_name, $sformatf("Link 1 targeted Gen %0d, resolved to Gen %0d", cxl_link_speed[1], curr_speed))
      else 
        `uvm_info(get_type_name, $sformatf("Link 1 in CXL mode at Gen %0dx%0d", curr_speed, curr_lw), UVM_NONE)
    end
  endtask

endclass

// Callback specific definition for these tests
class seq_enum_cb extends seq_enum_callback;

  `uvm_object_utils(seq_enum_cb)

  bit [2:0] cxl_link_speed[0:1];

  function new(string name = "seq_enum_cb");
    super.new(name);
  endfunction

  virtual task post_start(seq_enum seq);
    bit port_id;
    if (seq.dut_cfg.ctrlr_en[0]) begin
      port_id = 0;
      // Assign final link speed for CXL
      seq.p_sequencer.vip.cxl_port_set(port_id, "max_speed_sup", cxl_link_speed[0]);
      `uvm_info("TSTINFO", $sformatf("Bringing up CXL Link 0 to Gen %0d", cxl_link_speed[0]), UVM_LOW)
      // Give CXL LL credits if necessary
      seq.env.cxl_nfi_agnt_rx[0].txfer_init_credits;
    end
    if (seq.dut_cfg.ctrlr_en[1]) begin
      port_id = seq.dut_cfg.ctrlr_en[0];
      // Assign final link speed for CXL
      seq.p_sequencer.vip.cxl_port_set(port_id, "max_speed_sup", cxl_link_speed[1]);
      `uvm_info("TSTINFO", $sformatf("Bringing up CXL Link 1 to Gen %0d", cxl_link_speed[1]), UVM_LOW)
      // Give CXL LL credits if necessary
      seq.env.cxl_nfi_agnt_rx[1].txfer_init_credits;
    end
  endtask

endclass
