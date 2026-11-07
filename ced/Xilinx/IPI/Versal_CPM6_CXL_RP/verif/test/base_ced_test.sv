/* DESCRIPTION
 * Base test for this CED; not meant to be run on its own. Configures the
 * DUT with only controller 1 enabled as a CXL Root Port and the VIP as a
 * CXL Type 3 device, and disables the controller 0 agents.
 * After enumeration it collects the AXI interface (axi4_sim_if) of each CPI
 * datapath that was generated (axi4_vif[]) and the enumerated RP and EP
 * devices (rp_pdev, ep_pdev), so derived tests can drive the datapaths and
 * find the allocated BARs and CXL HDM ranges.
|*/
class base_ced_test extends base_cxl_rp_test;

  `uvm_component_utils(base_ced_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    // Controller enablement
    dut_ctrlr_en[1:0] = 2'b10;
    // Configure VIP as CXL Type 3 Device
    vip_cxl_dev_type = 3;
    vip_cxl_dev_type.rand_mode(0);
  endfunction

  // AXI4 interface of each CPI datapath, published by bind_axi_tg_override.
  // A handle stays null when that datapath was not generated.
  virtual axi4_sim_if axi4_vif[4];

  // Enumerated device objects of the root port (DUT) and the endpoint (VIP),
  // taken from the shim's container once enumeration has finished. They hold
  // the allocated BARs, apertures and CXL HDM ranges. Null if not found.
  pcie_device  rp_pdev;
  pcie_device  ep_pdev;

  // The interfaces are put in the config DB by an initial block at time 0,
  // which is not ordered against the function phases that also run at time
  // 0. Get them after enumeration (configure_phase), which consumes time. A
  // failed get means the design has fewer CPI instances than that index,
  // i.e. NUM_CPI was set lower.
  virtual task pre_main_phase(uvm_phase phase);
    int num_cpi;
    super.pre_main_phase(phase);
    for (int ii=0; ii<4; ii++) begin
      if (uvm_config_db#(virtual axi4_sim_if)::get(this, "",
            $sformatf("axi4_sim_vif[%0d]", ii), axi4_vif[ii]))
        num_cpi++;
      else
        `uvm_info(get_type_name(), $sformatf(
          "No AXI4 interface for CPI%0d; NUM_CPI is below %0d", ii, ii+1),
          UVM_LOW)
    end
    `uvm_info(get_type_name(), $sformatf("%0d CPI datapath(s) found",
                                         num_cpi), UVM_LOW)

    // Enumeration finished in configure_phase, so the devices are known now
    rp_pdev = env.shim.container.get_pdev_RP();
    ep_pdev = env.shim.container.get_pdev_EP();
    if (rp_pdev == null)
      `uvm_fatal(get_type_name(), "No RP pdev found in the container")
    if (ep_pdev == null)
      `uvm_fatal(get_type_name(), "No EP pdev found in the container")
  endtask

  virtual function void setup_env_cfg();
    // Controller 0 agents' enablement
    env_cfg.cxl_nfi_agnt_tx[0]    = UNUSED_AGNT;
    env_cfg.cxl_nfi_agnt_rx[0]    = UNUSED_AGNT;
    env_cfg.cxl_cfgsts_agnt[0]    = UNUSED_AGNT;
    env_cfg.cxl_pm_in_agnt [0]    = UNUSED_AGNT;
    env_cfg.cxl_pm_out_agnt[0]    = UNUSED_AGNT;
    env_cfg.cxl_credit_agnt_tx[0] = UNUSED_AGNT;
    env_cfg.cxl_credit_agnt_rx[0] = UNUSED_AGNT;
    env_cfg.elbi_agnt[0]          = UNUSED_AGNT;
  endfunction

endclass
