class cap_base extends cap_foundation;

  `uvm_object_utils(cap_base)

  // RO version for referencing (Questa doesn't allow const)
  pcie_capid_e cap_id;

  function new(string name = "cap_base");
    super.new(name);
  endfunction

endclass
