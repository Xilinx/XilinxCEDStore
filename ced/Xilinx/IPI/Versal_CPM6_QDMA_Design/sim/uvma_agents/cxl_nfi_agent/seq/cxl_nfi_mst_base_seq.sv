class cxl_nfi_mst_base_seq#(parameter NFI_W=3) extends cxl_nfi_base_seq#(NFI_W);

  `uvm_object_param_utils(cxl_nfi_mst_base_seq#(NFI_W))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("cxl_nfi_mst_base_seq#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  // Extended sequences will put txns here then send them
  flit_base_txn flit_q[$];

  // Control knobs
  bit ignore_avail_credits = 1'b0; 

  // Enhancement : add link layer slots or invalid flits between valid slotsets
  bit insert_invalid_flits = 1'b0;
  bit insert_ll_slots      = 1'b0;

  function new(string name = "cxl_nfi_mst_base_seq");
    super.new(name);
  endfunction

endclass
