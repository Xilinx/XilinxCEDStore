class ecap_base extends cap_foundation;

  `uvm_object_utils(ecap_base)

  // RO version for referencing (Questa doesn't allow const)
  pcie_ecapid_e cap_id;

  function new(string name = "ecap_base");
    super.new(name);
  endfunction

endclass
