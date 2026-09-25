class cxl_nfi_credit_txn extends base_txn;

  `uvm_object_utils(cxl_nfi_credit_txn)

  // 1:mem, 0:cache
  int req_cred[1:0];
  int dat_cred[1:0];
  int rsp_cred[1:0];

  function new(string name = "cxl_nfi_credit_txn");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    cxl_nfi_credit_txn t;
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from cxl_nfi_credit_txn")
    super.do_copy(rhs);
    t.req_cred = t.req_cred;
    t.dat_cred = t.dat_cred;
    t.rsp_cred = t.rsp_cred;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    `uvm_warning(get_type_name, "do_compare not implemented for this transaction")
    do_compare = 0;
  endfunction

  function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_int("req_cred[MEM]", req_cred[1], 32, UVM_DEC);
    printer.print_int("dat_cred[MEM]", dat_cred[1], 32, UVM_DEC);
    printer.print_int("rsp_cred[MEM]", rsp_cred[1], 32, UVM_DEC);
    printer.print_int("req_cred[CCH]", req_cred[0], 32, UVM_DEC);
    printer.print_int("dat_cred[CCH]", dat_cred[0], 32, UVM_DEC);
    printer.print_int("rsp_cred[CCH]", rsp_cred[0], 32, UVM_DEC);
  endfunction

endclass
