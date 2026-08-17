class test_ide_tlps_spdm extends test_ide_tlps;

  `uvm_component_utils(test_ide_tlps_spdm)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    bypass_spdm_flow = 1'b0;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    uvm_factory factory = uvm_factory::get();
    factory.set_type_override_by_type(cseq_core_doe_discovery_cfg_mb::get_type(), cseq_core_doe_emu_cfg_mb::get_type());
    super.build_phase(phase);
  endfunction
endclass
