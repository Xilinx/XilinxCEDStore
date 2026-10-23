class isr_cb extends gpmon_mon_cb#(gpmon_txn);

  `uvm_object_utils(isr_cb)

  function new(string name = "isr_cb");
    super.new(name);
  endfunction

  virtual function void make_specific(gpmon_txn txn);
    txn.sig_enum = "{CORR, UNCORR, MISC}";
  endfunction

endclass
