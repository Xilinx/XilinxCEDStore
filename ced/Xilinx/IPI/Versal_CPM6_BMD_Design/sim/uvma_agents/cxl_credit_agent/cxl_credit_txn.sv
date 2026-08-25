class cxl_credit_txn extends base_txn;

  `uvm_object_utils(cxl_credit_txn)

  logic [3:0] credit;

  function new(string name = "cxl_credit_txn");
    super.new(name);
    txn_type = "CXL_CREDIT_TXN";
  endfunction

  // Decodes the lookup
  virtual function int convert2dec();
    convert2dec = !credit[2:0] ? 0 : 2**(credit[2:0]-1);
  endfunction

  virtual function int get_mem_credits();
    get_mem_credits = credit[3] ? convert2dec : 0;
  endfunction

  virtual function int get_cch_credits();
    get_cch_credits = credit[3] ? 0 : convert2dec;
  endfunction

  function void do_print(uvm_printer printer);
    string val;
    super.do_print(printer);
    val = credit[3] ? "CXL.mem" : "CXL.cache";
    printer.print_string("protocol", val);
    printer.print_string("credit",   $sformatf("'h%h (%0d)",credit[2:0], convert2dec));
  endfunction 

  virtual function void do_copy(uvm_object rhs);
    cxl_credit_txn t;
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't a child of cxl_credit_txn")
    super.do_copy(rhs);
    credit = t.credit;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    cxl_credit_txn _rhs;
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "do_compare got a txn that wasn't a base class of credit_txn")
    do_compare  = comparer.compare_string   ("txn_type", txn_type, _rhs.txn_type);
    do_compare &= comparer.compare_string   ("info",     info,     _rhs.info);
    do_compare &= comparer.compare_string   ("uid",      uid,      _rhs.uid);
    do_compare &= comparer.compare_field_int("credit",   credit,   _rhs.credit,  4);
  endfunction

endclass
