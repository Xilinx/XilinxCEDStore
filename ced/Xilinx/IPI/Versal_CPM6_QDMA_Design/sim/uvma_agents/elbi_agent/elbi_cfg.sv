class elbi_cfg extends base_cfg;

  `uvm_object_utils(elbi_cfg)

  function new(string name = "elbi_cfg");
    super.new(name);
  endfunction

  bit shared_responder;

  virtual function void do_copy(uvm_object rhs);
    elbi_cfg _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      shared_responder = _rhs.shared_responder;
    end
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_int   ("shared_responder", shared_responder, 1, UVM_BIN);
  endfunction

endclass
