class gpdrv_txn extends base_txn;

  `uvm_object_utils(gpdrv_txn)

  logic [63:0] sig;
  int unsigned width;

  string         sig_enum;
  string         ml_sig_enum[$:32]; //ml = "multi-line"
  uvm_radix_enum print_radix;

  function new(string name = "gpdrv_txn");
    super.new(name);
    txn_type = "GPDRV_TXN";
  endfunction 

  virtual function void do_copy(uvm_object rhs);
    gpdrv_txn t; 
    super.do_copy(rhs);
    if (!$cast(t,rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from gpdrv_txn")
    width       = t.width;
    sig         = t.sig;
    sig_enum    = t.sig_enum;
    ml_sig_enum = t.ml_sig_enum;
    print_radix = t.print_radix;
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("value", sig, min(width, 64), print_radix);
    if (sig_enum != "")
      printer.print_string("enum", sig_enum);
    foreach (ml_sig_enum[ii])
      printer.print_string($sformatf("enum[%0d]",ii) , ml_sig_enum[ii]);
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    gpdrv_txn t;
    do_compare = super.do_compare(rhs, comparer);
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_compare got a txn that wasn't extended from gpdrv_txn")
    do_compare &= comparer.compare_field_int("sig",   sig,   t.sig,   min(width,64)); 
    do_compare &= comparer.compare_field_int("width", width, t.width, 32);
  endfunction

endclass
