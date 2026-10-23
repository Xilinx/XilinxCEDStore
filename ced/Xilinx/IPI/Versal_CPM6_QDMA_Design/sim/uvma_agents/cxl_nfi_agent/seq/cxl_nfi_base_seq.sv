class cxl_nfi_base_seq#(parameter NFI_W=3) extends uvm_sequence#(cxl_nfi_txn#(NFI_W));

  `uvm_object_param_utils(cxl_nfi_base_seq#(NFI_W))
  `uvm_declare_p_sequencer(cxl_nfi_sequencer#(NFI_W))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("cxl_nfi_base_seq#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name = "cxl_nfi_base_seq");
    super.new(name);
  endfunction

endclass
