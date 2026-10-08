/* DESCRIPTION
 * This class configures the VIP as RP and DUT as EP and instructs both to 
   link up in PCIe mode so tests need not worry about these common settings.
|*/

class base_ep_test extends test_enum;

  `uvm_component_utils(base_ep_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  logic [1:0] dut_ctrlr_en;

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    // Default each DUT controller to enabled, which affects CDO programming
    // Extended tests should set these members before this phase
    if (!$value$plusargs("CTRLR0_EN=%b",dut_ctrlr_en[0]) && dut_ctrlr_en[0]===1'bx)
      dut_ctrlr_en[0] = 1'b1;
    if (!$value$plusargs("CTRLR1_EN=%b",dut_ctrlr_en[1]) && dut_ctrlr_en[1]===1'bx)
      dut_ctrlr_en[1] = 1'b1;
    // Basic setup
    for (int ii=0; ii<2; ii++) begin
      // VIP as RP
      vip_cfg.ctrlr_en[ii] = 1'b1;
      vip_cfg.port_ctl[ii] = generic_config::PCIE;
      vip_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::RP;
      // DUT as EP
      dut_cfg.ctrlr_en[ii] = dut_ctrlr_en[ii];
      dut_cfg.port_ctl[ii] = generic_config::PCIE;
      dut_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::EP;
    end
  endfunction

endclass
