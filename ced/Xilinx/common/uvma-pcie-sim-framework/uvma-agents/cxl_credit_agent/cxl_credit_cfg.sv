class cxl_credit_cfg extends base_cfg;

  `uvm_object_utils(cxl_credit_cfg)

  bit mon_indi;            //monitor broadcasts several cxl_credit_txns, not one cxl_credit_bus_txn
  bit cmp_zero;            //compare all (even zero) credits in cxl_credit_bus_txn.do_compare
  bit broadcast_all;       //send all txns out analysis ports, not only nonzero
  bit mst_use_credit_pool; //iff a MASTER, this will add credits to pool from impl port and 
                           //start the pool sequence to transmit and subtract from pool

  function new(string name = "cxl_credit_cfg");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    cxl_credit_cfg _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      mon_indi            = _rhs.mon_indi;
      cmp_zero            = _rhs.cmp_zero;
      broadcast_all       = _rhs.broadcast_all;
      mst_use_credit_pool = _rhs.mst_use_credit_pool;
    end
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_int   ("mon_indi",            mon_indi,            1, UVM_BIN);
    printer.print_int   ("cmp_zero",            cmp_zero,            1, UVM_BIN);
    printer.print_int   ("broadcast_all",       broadcast_all,       1, UVM_BIN);
    printer.print_int   ("mst_use_credit_pool", mst_use_credit_pool, 1, UVM_BIN);
  endfunction

endclass
