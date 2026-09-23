/* DESCRIPTION
 * This class configures the DUT as CXL RP and VIP as CXL EP and instructs 
 * both to link up in CXL mode so tests need not worry about these common 
 * settings.
|*/

class base_cxl_rp_test extends test_enum;

  `uvm_component_utils(base_cxl_rp_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  logic [1:0] dut_ctrlr_en;

  // Randomize VIP to support CXL.mem
  rand bit   [1:0] vip_cxl_dev_type;

  constraint c_vip_cxl_dev_type { vip_cxl_dev_type inside {2,3}; }
  
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    // Perform some initial randomization and disable them re-randomizing
    void'(this.randomize());
    vip_cxl_dev_type.rand_mode(0);
    // Default each DUT controller to enabled, which affects CDO programming
    // Extended tests should set these members before this phase 
    if (!$value$plusargs("CTRLR0_EN=%b",dut_ctrlr_en[0]) && dut_ctrlr_en[0]===1'bx)
      dut_ctrlr_en[0] = 1'b1; 
    if (!$value$plusargs("CTRLR1_EN=%b",dut_ctrlr_en[1]) && dut_ctrlr_en[1]===1'bx)
      dut_ctrlr_en[1] = 1'b1; 
    // Default ECAM base to a common value 
    if (!$value$plusargs("ECAM_BASE=0x%h",bus_enum.ecam_base))
      bus_enum.ecam_base = 'hE000_0000;
    // Basic setup
    for (int ii=0; ii<2; ii++) begin
      // DUT as EP
      dut_cfg.ctrlr_en[ii] = dut_ctrlr_en[ii];
      dut_cfg.use_case[ii] = dut_config::CXL_DMA;
      dut_cfg.port_ctl[ii] = generic_config::PCIE_CXL;
      dut_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::RP;
      dut_cfg.cxl_cfg [ii].cxl_device_type = 3; //CXL.mem only
      // VIP as RP
      vip_cfg.ctrlr_en[ii] = 1'b1;
      vip_cfg.port_ctl[ii] = generic_config::PCIE_CXL;
      vip_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::EP;
      vip_cfg.cxl_cfg [ii].cxl_device_type = vip_cxl_dev_type;
    end
    // RTL sims need CDO
    if ($test$plusargs("CPM6_RTL")) begin
      //dut_cfg.base_cdo = "<some file>.cdo.anno";
      `uvm_fatal(get_type_name, "Do not have a CDO file to use for CPM6 CXL RP")
    end
    // - Will need two VIP instances in shim
    if (&dut_ctrlr_en)
      `uvm_fatal(get_type_name, "Dual controller RP DUT not supported yet")
  endfunction

endclass
